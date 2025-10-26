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
final class ChatViewManager: ChatViewUpdaterDelegate, ErrorPresenter {

	@ObservationIgnored let datasource: ChatDatasource
	@ObservationIgnored var scrollManager: ChatScrollManager
	@ObservationIgnored var eventsManager: ChatViewEventsManager
	@ObservationIgnored let viewUpdater: ChatViewUpdater
	@ObservationIgnored private var viewCache = [String: _opaque_View]()
	@ObservationIgnored let bubbleFactory: BubbleFactory
	@ObservationIgnored let prefetcher: ScrollViewPrefetcher
	var conversation: any ConversationRepresentable
	var cellItems = [MsgCellViewModel]()
	var config: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentAPI = AttachmentDataAPI()
	@ObservationIgnored var attachmentFetcher: AsyncFetcher<AttachmentData>?

	init(_ data: ConversationInitializer.PrefetchedData) {
		ColorStorage.shared.initialize(data.conversation)
		config = data.configuration
		datasource = .init(config: data.configuration)
		scrollManager = .init()
		eventsManager = .init(config: data.configuration)
		viewUpdater = .init()
		bubbleFactory = .init()
		prefetcher = .init(windowSize: 5)
		conversation = data.conversation
		viewUpdater.delegate = self
		prefetcher.delegate = self
		scrollManager.delegate = self
		datasource.delegate = viewUpdater
		cellItems = data.msgs.map(MsgCellViewModel.init)
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
	func view(for viewModel: MsgCellViewModel, bubble: Bubble) -> _opaque_View {
		if let cached = viewCache[viewModel.id] {
			return cached._opaque_environment(viewModel)
		}
		let view =  MsgCell(bubble).opaqueView()._opaque_environment(viewModel)
		if viewModel.id != cellItems.last?.id {
			viewCache[viewModel.id] = view
		}
		return view
	}
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
	var canAdjustWindows: Bool {
		cellItems.count > config.maxNumberOfMsgsToDisplay
	}
	var lastMsg: Message? { cellItems.last?.msg }
	var firstMsg: Message? { cellItems.first?.msg }

	func scrollManager(_ manager: ChatScrollManager, removeItemsAt edge: VerticalEdge, itemCount: Int) {
		switch edge {
		case .top:
			cellItems = cellItems.removingPrefix(itemCount)
		case .bottom:
			cellItems = cellItems.removingSuffix(itemCount)
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Database.Message) {
		let pageSize = max(1, config.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize/2 : 1
		if cellItems.count >= pageSize * 2 {
			cellItems = cellItems.takingPrefix(pageSize)
		} else {
			cellItems = cellItems.takingPrefix(trimCount)
		}
		let expectedFirstID = msg.uid
		Task { [weak self] in
			guard let self else { return }
			let query = ServerTime(msg.date).value
			do {
				guard !Task.isCancelled else { return }
				guard self.scrollManager.updatingState.isUpdating else { return }
				let msgs = try await self.datasource.loadPrevious(before: query, conID: msg.conID)
				guard !Task.isCancelled else { return }
				// Ensure we’re still loading previous near the same boundary (best-effort check)
				if self.cellItems.first?.id == expectedFirstID || self.scrollManager.updatingState.isUpdating {
					self.viewUpdater.insert(msgs: msgs)
					self.scrollManager.layoutCache.layout.setMsgCellLayout(nil, for: msg.uid)
				}
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadMore msg: Database.Message) {
		Task { [weak self] in
			guard let self else { return }
			let query = ServerTime(msg.date).value
			do {
				let msgs = try await self.datasource.loadMore(after: query, conID: msg.conID)
				guard !Task.isCancelled else { return }
				if self.scrollManager.updatingState.isUpdating {
					self.viewUpdater.insert(msgs: msgs)
					self.scrollManager.layoutCache.layout.setMsgCellLayout(nil, for: msg.uid)
				}
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}
	var canResetDatasource: Bool {
		scrollManager.canLoadMore
	}
	func resetDatasource() {
		guard scrollManager.updatingState.isNotUpdating else { return }
		guard canResetDatasource else {
			scrollManager.scroll(to: .bottom(animated: true, duration: nil))
			return
		}

		guard let lastId = cellItems.last?.id else {
			return
		}
		eventsManager.canShowScrollButton = false
		scrollManager.updateLoadingState(.resetting)
		scrollManager.scroll(to: lastId, animated: true) { [weak self] in
			MainActor.assumeIsolated {
				guard let self else { return }
				Task {
					do {
						let msgs = try await self.datasource.reset(conID: self.config.conID)
						self.setCellItems(msgs)
						self.scrollManager.setScrollPosition(to: .init(edge: .bottom))
					} catch {
						await self.showError(error)
					}
				}
			}
		}

	}

	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: XUI.ScrolledPosition) {
		switch position {
		case .atBottom:
			eventsManager.canShowScrollButton = false
			if manager.updatingState.isNotUpdating && !canLoadMore && cellItems.count > config.pageSize + 5 {
				cellItems = cellItems.takingSuffix(config.pageSize)
				manager.setScrollPosition(to: .init(edge: .bottom))
			}
		default:
			eventsManager.canShowScrollButton = true
		}
	}

	func setCellItems(_ msgs: [Message]) {
		var newItems = [MsgCellViewModel]()
		msgs.enumerated.forEach { (_, msg) in
			if let vm = cellItems.first(where: { $0.id == msg.uid }) {
				newItems.append(vm)
			} else {
				newItems.append(.init(msg))
			}
		}
		cellItems = newItems
	}
}

extension ChatViewManager {
	func handleTappingChanged(_ location: CGPoint) {
		guard let layout = scrollManager.layoutCache.layout.layout(for: location) else { return }
		guard let viewModel = cellItems.first(where: { $0.id == layout.id }) else { return }
		setSelectedMsg(viewModel.id)
	}
	func handlePressingChanged(_ location: CGPoint?) {
		guard let location else {
			return
		}
		let scrollGeometry = scrollManager.getScrollGeometry()
		let eventY = scrollGeometry.visibleRect.minY + location.y
		guard let layout = scrollManager.layoutCache.layout.layout(for: .init(x: location.x, y: eventY)) else { return }
		guard cellItems.viewModel(of: layout.id) != nil else { return }
		var frame = layout.frame
		frame.origin.y -= scrollGeometry.visibleRect.minY
		frame.size.width -= ChatLayoutConstants.Cell.defaultSpacing-4
		eventsManager.updateFocusedFrame(.init(id: layout.id, frame: frame))
	}
}

extension ChatViewManager {
	func msgCellLayoutFor(_ msg: Message) -> MsgCellLayout {
		guard let index = cellItems.index(of: msg.uid) else { return MsgCellLayout() }
		if index > 0 && index < cellItems.count-1, let cached = scrollManager.layoutCache.layout.msgCellLayout(for: msg.uid) {
			return cached
		}
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let layout = bubbleFactory.msgCellLayout(for: msg, previous: previous, next: next)
		if previous != nil && next != nil {
			scrollManager.layoutCache.layout.setMsgCellLayout(layout, for: msg.uid)
		}
		return layout
	}
}

extension ChatViewManager {
	func setSelectedMsg(_ uid: String) {
		Task {
			let oldValue = eventsManager.selectedMsg
			guard let index = cellItems.firstIndex(where: { $0.id == uid }) else { return }
			let next = cellItems[safe: index + 1]?.msg
			let previous = cellItems[safe: index - 1]?.msg
			let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(id: uid, previous: previous?.uid, next: next?.uid)
			eventsManager.updateSelectedMsg(newValue, animated: true)
			if scrollManager.isFirstResponder {
				UIApplication.shared.endEditing()
			}
			scrollManager.layoutCache.layout.invalidateLayout()
			if let newValue, newValue.id == scrollManager.visibleViewIDs.first || newValue.id == scrollManager.visibleViewIDs.last {
				DispatchQueue.delay {
					MainActor.assumeIsolated {
						self.scrollManager.scroll(to: newValue.id+MsgCellFooter.typeName)
					}
				}
			}
		}
	}
}

extension ChatViewManager {
	@concurrent
	func onViewAppear() async {
		if await scrollManager.updatingState.hasViewLoaded {
			try? await viewUpdater.reloadConversation()
			await MainActor.run {
				ColorStorage.shared.initialize(conversation)
			}
		} else {
			await datasource.setupNotificationObserver()
			await scrollManager.setHasViewUpdated()
			await viewUpdater.updateConversation()
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
		let ids = indices.compactMap{ cellItems[safe: $0] }.filter{ $0.msg.attachment != nil && $0.attachment.thumbnail == nil }.map{
			$0.id
		}
		Task {
			await attachmentFetcher.prefetch(ids)
		}
	}

	func prefetcher(_ prefetcher: ScrollViewPrefetcher, cancelPrefetchingFor indices: [Int]) {
		guard let attachmentFetcher else { return }
		let ids = indices.compactMap{ cellItems[safe: $0] }.filter{ $0.msg.attachment != nil }.map{
			$0.id
		}
		Task {
			await attachmentFetcher.cancelPrefetch(ids)
		}
	}
}
