//
//  ChatViewManager.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/10/24.
//

import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatViewManager: ErrorPresenter {

	@ObservationIgnored let datasource: ChatDatasource
	@ObservationIgnored var scrollManager: ChatScrollManager
	@ObservationIgnored var eventsManager: ChatViewEventsManager
	@ObservationIgnored let bubbleFactory: BubbleFactory
	@ObservationIgnored let prefetcher: ScrollViewPrefetcher
	var conversation: any ConversationRepresentable
	@ObservationIgnored var config: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentAPI = AttachmentDataAPI()
	@ObservationIgnored var attachmentFetcher: AsyncFetcher<AttachmentData>?
	var cellItems = [MsgCellViewModel]()

	init(_ data: ConversationInitializer.PrefetchedData) {
		config = data.configuration
		datasource = .init(config: data.configuration)
		scrollManager = .init()
		eventsManager = .init(config: data.configuration)
		bubbleFactory = .init()
		prefetcher = .init(windowSize: 5)
		conversation = data.conversation
		prefetcher.delegate = self
		scrollManager.delegate = self
		datasource.delegate = self
		let items = createCellItems(for: data.msgs, forceReset: true)
		performUpdate(to: items)
		attachmentFetcher = AsyncFetcher(fetch: { [weak self] id in
			guard let self else { throw CancellationError() }
			guard let msg = await self.cellItems.viewModel(of: id)?.msg else {
				throw CancellationError()
			}
			return try await self.attachmentAPI.fetchAttachmentData(for: msg)
		})
	}
	deinit {
		Log("Deinit")
	}
}

extension ChatViewManager: ChatScrollManagerDelegate {
	var canLoadPrevious: Bool {
		guard let firstMsgID = config.firstMsgID else { return false }
		guard cellItems.isEmpty == false else { return false }
		return !cellItems.contains(where: { $0.id == firstMsgID })
	}
	var canLoadMore: Bool {
		guard let lastMsgID = config.lastMsgID else { return false }
		guard cellItems.isEmpty == false else { return false }
		return !cellItems.contains(where: { $0.id == lastMsgID })
	}
	var lastMsg: Message? { cellItems.last?.msg }
	var firstMsg: Message? { cellItems.first?.msg }

	func scrollManager(_ manager: ChatScrollManager, removeItemsAt edge: VerticalEdge, itemCount: Int) {
		let items: [MsgCellViewModel]
		switch edge {
		case .top:
			items = cellItems.removingPrefix(itemCount)
		case .bottom:
			items = cellItems.removingSuffix(itemCount)
		}
		performUpdate(to: items)
	}

	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Database.Message) {
		manager.updateLoadingState(.removingItems(.bottom))
		let pageSize = max(1, config.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize/2 : 1
		let items: [MsgCellViewModel]
		if cellItems.count >= pageSize * 2 {
			items = cellItems.takingPrefix(pageSize)
		} else {
			items = cellItems.takingPrefix(trimCount)
		}
		cellItems = items
		items.first?.resetLayout()
		items.last?.resetLayout()
		Task {
			scrollManager.updateLoadingState(.insertingItems(.top))
			let query = ServerTime(msg.date).value
			do {
				let msgs = try await datasource.loadPrevious(before: query, conID: msg.conID)
				let cellItems = createCellItems(for: msgs, forceReset: false)
				performUpdate(to: cellItems)
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}
	func scrollManager(_ manager: ChatScrollManager, loadMore msg: Database.Message) {
		Task {
			let query = ServerTime(msg.date).value
			do {
				let msgs = try await self.datasource.loadMore(after: query, conID: msg.conID)
				let cellItems = createCellItems(for: msgs, forceReset: false)
				performUpdate(to: cellItems, animated: manager.isScrolling)
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}
	var canResetDatasource: Bool {
		canLoadMore
	}
	func resetDatasource() {
		eventsManager.canShowScrollButton = false
		guard canResetDatasource else {
			scrollManager.scroll(to: .bottom(animated: true))
			return
		}
		scrollManager.updateLoadingState(.resetting)
		Task {
			do {
				let msgs = try await datasource.reset(conID: config.conID)
				let cellItems = createCellItems(for: msgs, forceReset: true)
				performUpdate(to: cellItems)
				scrollManager.setScrollPosition(to: .init(edge: .bottom))
			} catch {
				await self.showError(error)
			}
		}
	}

	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: XUI.ScrolledPosition) {
		switch position {
		case .atBottom:
			eventsManager.canShowScrollButton = false
			if manager.updatingState.isNotUpdating && !canLoadMore && cellItems.count > config.pageSize + 5 {
				let items = cellItems.takingSuffix(config.pageSize)
				performUpdate(to: items)
				manager.setScrollPosition(to: .init(edge: .bottom))
			}
		default:
			eventsManager.canShowScrollButton = true
		}
	}
}

extension ChatViewManager {
	func msgCellLayoutFor(_ msg: Message) -> MsgCellLayout {
		msgCellLayoutFor(msg, cellItems: cellItems)
	}
	func msgCellLayoutFor(_ msg: Message, cellItems: [MsgCellViewModel]) -> MsgCellLayout {
		guard let index = cellItems.index(of: msg.uid) else { return MsgCellLayout() }
		if index > 0 && index < cellItems.count-1, let cached = scrollManager.layoutCache.msgCellLayout(for: msg.uid) {
			return cached
		}
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let layout = bubbleFactory.msgCellLayout(for: msg, previous: previous, next: next)
		if index > 0 && index < cellItems.count-1, previous != nil && next != nil {
			scrollManager.layoutCache.setMsgCellLayout(layout, for: msg.uid)
		}
		return layout
	}
}

extension ChatViewManager {
	func setSelectedMsg(_ uid: String) {
		let oldValue = eventsManager.selectedMsg
		guard let index = cellItems.firstIndex(where: { $0.id == uid }) else { return }
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(id: uid, previous: previous?.uid, next: next?.uid)
		eventsManager.updateSelectedMsg(newValue)
		var transaction = Transaction()
		transaction.animation = .interactiveSpring

		if let newValue, let item = cellItems.viewModel(of: newValue.id) {
			item.setSelected(true)
		} else {
			if let oldValue, let item = cellItems.viewModel(of: oldValue.id) {
				item.setSelected(false)
			}
		}

	}
}

extension ChatViewManager {
	func onViewAppear() async {
		if scrollManager.updatingState.hasViewLoaded {
			if let reloaded = try? await conversation.reload(refetch: false) {
				await MainActor.run {
					self.conversation = reloaded
				}
			}
		} else {
			scrollManager.setHasViewUpdated()
			if let reloaded = try? await conversation.reload(refetch: true) {
				await MainActor.run {
					self.conversation = reloaded
				}
			}
			updateReceiveMsgs()
		}
	}
}

extension ChatViewManager: ScrollViewPrefetcherDelegate {
	func handleVisibleIDsChange(_ uids: [String]) {
		let differences = uids.difference(from: scrollManager.visibleViewIDs)
		var inserts = [String]()
		for difference in differences {
			switch difference {
			case .insert(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.setVisibility(true)
					}
					prefetcher.onAppear(index)
				}
				inserts.append(id)
			case .remove(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.setVisibility(false)
					}
					prefetcher.onDisappear(index)
				}
			}
		}
		scrollManager.handleVisibleIDsChange(uids)
		if let uid = inserts.last,
		   let msg = cellItems.viewModel(of: uid)?.msg {
			eventsManager.updateFloatingDate(msg.date)
		}
	}
	func allIndices(for prefetcher: ScrollViewPrefetcher) -> Range<Int> {
		cellItems.indices
	}

	func prefetcher(_ prefetcher: ScrollViewPrefetcher, prefetchItemsAt indices: [Int]) {
		guard let attachmentFetcher else { return }
		let ids = indices
			.compactMap { cellItems[safe: $0] }
			.filter { $0.msg.attachment != nil && $0.attachment.thumbnail == nil }
			.map { $0.id }
		Task {
			await attachmentFetcher.prefetch(ids)
		}
	}

	func prefetcher(_ prefetcher: ScrollViewPrefetcher, cancelPrefetchingFor indices: [Int]) {
		guard let attachmentFetcher else { return }
		let ids = indices.compactMap { cellItems[safe: $0] }.filter { $0.msg.attachment != nil }.map {
			$0.id
		}
		Task {
			await attachmentFetcher.cancelPrefetch(ids)
		}
	}
}
