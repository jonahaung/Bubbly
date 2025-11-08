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

@Observable
final class ChatViewManager: ErrorPresenter, ViewReloadable {

	@ObservationIgnored let datasource: ChatDatasource
	@ObservationIgnored var scrollManager: ChatScrollManager
	@ObservationIgnored var eventsManager: ChatViewEventsManager
	@ObservationIgnored let bubbleFactory: BubbleFactory
	@ObservationIgnored let prefetcher: ScrollViewPrefetcher
	@ObservationIgnored var config: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentAPI = AttachmentDataAPI()
	@ObservationIgnored var attachmentFetcher: AsyncFetcher<AttachmentData>?
	var conversation: any ConversationRepresentable
	var cellItems = [MsgCellViewModel]()
	var reloadID: Int = 0

	init(_ data: ConversationInitializer.PrefetchedData) {
		config = data.configuration
		datasource = .init(config: data.configuration)
		scrollManager = .init()
		eventsManager = .init(config: data.configuration)
		bubbleFactory = .init()
		prefetcher = .init(windowSize: 5)
		conversation = data.conversation

		let items = createCellItems(for: data.msgs, forceReset: true)
		setCellItems(items)
		attachmentFetcher = AsyncFetcher(fetch: { [weak self] id in
			guard let self else { throw CancellationError() }
			guard let msg = await self.cellItems.viewModel(of: id)?.msg else {
				throw CancellationError()
			}
			return try await self.attachmentAPI.fetchAttachmentData(for: msg)
		})
		trackItemsChanges()
		prefetcher.delegate = self
		scrollManager.delegate = self
		datasource.delegate = self
	}
	deinit {
		Log("Deinit")
	}

	func trackItemsChanges() {
		withObservationTracking {
			_ = cellItems.count
			_ = eventsManager.selectedMsg
		} onChange: { [weak self] in
			guard let self else { return }
			Task { @MainActor in
				layoutIfNeeded()
				trackItemsChanges()
			}
		}
	}
}

extension ChatViewManager: ChatScrollManagerDelegate {
	var lastMessage: Database.Message? {
		cellItems.last?.msg
	}

	var firstMessage: Database.Message? {
		cellItems.first?.msg
	}

	var canLoadPrevious: Bool {
		guard let firstMsgID = config.firstMsgID else { return false }
		guard !cellItems.isEmpty else { return false }
		return !cellItems.contains(where: { $0.id == firstMsgID })
	}
	var canLoadMore: Bool {
		guard let lastMsgID = config.lastMsgID else { return false }
		guard !cellItems.isEmpty else { return false }
		return !cellItems.contains(where: { $0.id == lastMsgID })
	}

	func scrollManager(
		_ manager: ChatScrollManager,
		removeItemsAt edge: VerticalEdge,
		itemCount: Int
	) {
		switch edge {
		case .top:
			cellItems = cellItems.removingPrefix(itemCount)
		case .bottom:
			cellItems = cellItems.removingSuffix(itemCount)
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Message) {
		manager.updateLoadingState(.removingItems(.bottom))
		let pageSize = max(1, config.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize/2 : 1
		if cellItems.count >= pageSize * 2 {
			cellItems = cellItems.takingPrefix(pageSize)
		} else {
			cellItems = cellItems.takingPrefix(trimCount)
		}
		layoutIfNeeded()
		Task {
			let query = ServerTime(msg.date).value
			scrollManager.updateLoadingState(.insertingItems(.top))
			do {
				let msgs = try await datasource.loadPrevious(before: query, conID: msg.conID)
				let cellItems = createCellItems(for: msgs, forceReset: false)
				setCellItems(cellItems)
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}
	func scrollManager(_ manager: ChatScrollManager, loadMore msg: Message) {
		Task {
			let query = ServerTime(msg.date).value
			do {
				let msgs = try await self.datasource.loadMore(after: query, conID: msg.conID)
				let cellItems = createCellItems(for: msgs, forceReset: false)
				setCellItems(cellItems, animated: manager.isScrolling)
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
		guard canResetDatasource else {
			scrollManager.scroll(to: .bottom())
			return
		}
		Task {
			scrollManager.updateLoadingState(.resetting)
			do {
				let msgs = try await datasource.reset(conID: config.conID)
				if let middle = msgs.middleElement {
					scrollManager.setScrollPosition(to: .init(id: middle.uid, anchor: .top))
				}
				let cellItems = createCellItems(for: msgs, forceReset: true)
				setCellItems(cellItems)
			} catch {
				await self.showError(error)
			}
		}
	}

	func scrollManager(
		_ manager: ChatScrollManager,
		finalizeScrollViewUpdate position: XUI.ScrolledPosition
	) {
		switch position {
		case .atBottom:
			eventsManager.canShowScrollButton = false
			if manager.updatingState.isNotUpdating && !canLoadMore && cellItems.count > config.pageSize + 10 {
				cellItems = cellItems.takingSuffix(config.pageSize)
			}
		default:
			eventsManager.canShowScrollButton = true
		}
	}
	func scrollManager(reloadScrollView manager: ChatScrollManager) {
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func msgCellLayoutFor(_ msg: Message) -> MsgCellLayout {
		msgCellLayoutFor(msg, cellItems: cellItems)
	}
	func msgCellLayoutFor(_ msg: Message, cellItems: [MsgCellViewModel]) -> MsgCellLayout {
		guard let index = cellItems.index(of: msg.uid) else { return MsgCellLayout() }
		if index > 0 && index < cellItems.count-1, let cached = scrollManager.layoutCache.msgCellLayout(
			for: msg.uid
		) {
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
		let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(
			id: uid,
			previous: previous?.uid,
			next: next?.uid
		)
		if let newValue, let item = cellItems.viewModel(of: newValue.id) {
			item.setSelected(true)
		}
		if let oldValue, let item = self.cellItems.viewModel(of: oldValue.id) {
			DispatchQueue.delay {
				item.setSelected(false)
			}
		}
		eventsManager.updateSelectedMsg(newValue)
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
		let differences = uids.difference(from: scrollManager.visibleIDs)
		var inserts = [String]()
		for difference in differences {
			switch difference {
			case .insert(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.setVisibility(true)
						if viewModel.msg.msgKind.shouldPrefatchData {
							prefetcher.onAppear(index)
						}
					}

				}
				inserts.append(id)
			case .remove(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.setVisibility(false)
						if viewModel.msg.msgKind.shouldPrefatchData {
							prefetcher.onDisappear(index)
						}
					}
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
