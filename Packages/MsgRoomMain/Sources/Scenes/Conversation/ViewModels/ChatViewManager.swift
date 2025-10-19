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
final class ChatViewManager: ChatViewUpdaterDelegate, ErrorPresenter {

	let datasource: ChatDatasource
	var scrollManager: ChatScrollManager
	let eventsManager: ChatViewEventsManager
	let viewUpdater: ChatViewUpdater

	let cache: ChatCache
	let bubbleFactory: BubbleFactory
	let prefetcher: ScrollViewPrefetcher

	var conversation: ConversationSnapshot
	var cellItems = [MsgCellViewModel]()
	var config: ConversationInitializer.Configuration { scrollManager.config }

	init(_ data: ConversationInitializer.PrefetchedData) {
		datasource = .init(config: data.configuration)
		scrollManager = .init(config: data.configuration)
		eventsManager = .init(config: data.configuration)
		viewUpdater = .init()
		cache = .init()
		bubbleFactory = .init()
		prefetcher = .init(windowSize: 5)
		conversation = data.conversation
		viewUpdater.delegate = self
		prefetcher.delegate = self
		scrollManager.delegate = self
		datasource.delegate = viewUpdater
		cellItems = data.msgs.map(MsgCellViewModel.init)
	}
	deinit {
		Log(Mirror(reflecting: self).children)
	}
}

extension ChatViewManager: ChatScrollManagerDelegate {
	func scrollManager(_ manager: ChatScrollManager, didUpdateBoundsWidth newValue: CGFloat) {
		
	}

	var canLoadPrevious: Bool {
		!cellItems.contains(where: { $0.id == config.firstMsgID })
	}
	var canLoadMore: Bool {
		!cellItems.contains(where: { $0.id == config.lastMsgID })
	}
	var canAdjustWindows: Bool {
		cellItems.count > config.maxNumberOfMsgsToDisplay
	}
	var lastMsg: MsgSnapshot? { cellItems.last?.msg }
	var firstMsg: MsgSnapshot? { cellItems.first?.msg }

	func scrollManager(_ manager: ChatScrollManager, removeItemsAt edge: VerticalEdge, itemCount: Int) {
		switch edge {
		case .top:
			cellItems = cellItems.removingPrefix(itemCount)
		case .bottom:
			cellItems = cellItems.removingSuffix(itemCount)
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Database.MsgSnapshot) {
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
					self.cache.layout.setMsgCellLayout(nil, for: msg.uid)
				}
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadMore msg: Database.MsgSnapshot) {
		Task { [weak self] in
			guard let self else { return }
			let query = ServerTime(msg.date).value
			do {
				let msgs = try await self.datasource.loadMore(after: query, conID: msg.conID)
				guard !Task.isCancelled else { return }
				if self.scrollManager.updatingState.isUpdating {
					self.viewUpdater.insert(msgs: msgs)
					self.cache.layout.setMsgCellLayout(nil, for: msg.uid)
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
			scrollManager.scroll(to: .bottom(animated: true))
			return
		}
		scrollManager.updateLoadingState(.resetting)
		Task { [weak self] in
			guard let self else { return }
			do {
				let msgs = try await self.datasource.reset(conID: self.config.conID)
				guard !Task.isCancelled else { return }
				self.setCellItems(msgs)
				scrollManager.queue(to: .bottom(animated: true, duration: 0.1))
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}

	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: XUI.ScrolledPosition) {
		switch position {
		case .atBottom:
			if manager.updatingState.isNotUpdating && !canLoadMore && cellItems.count > config.pageSize + 5 {
				manager.updateLoadingState(.resetting)
				cellItems = cellItems.takingSuffix(config.pageSize)
			}
		case .atTop:
			if manager.updatingState.isNotUpdating && !canLoadPrevious && cellItems.count > config.pageSize + 5 {
				manager.updateLoadingState(.removingItems(.bottom))
				cellItems = cellItems.takingPrefix(config.pageSize)
			}
		default:
			break
		}

	}

	func setCellItems(_ msgs: [MsgSnapshot]) {
		var newItems = [MsgCellViewModel]()
		msgs.enumerated.forEach { (i, msg) in
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
	func handleVisibleIDsChange(_ uids: [String]) {
		let differences = uids.difference(from: scrollManager.visibleViewIDs)
		var inserts = [String]()

		for difference in differences {
			switch difference {
			case .insert(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.onAppear()
					}
					prefetcher.onAppear(index)
				}
				inserts.append(id)
			case .remove(_, let id, _):
				if let index = cellItems.index(of: id) {
					if let viewModel = cellItems.viewModel(of: index) {
						viewModel.onDisappear()
					}
					prefetcher.onDisappear(index)
				}
			}
		}

		if let uid = inserts.first,
		   let msg = cellItems.viewModel(of: uid)?.msg {
			eventsManager.updateFloatingDate(msg.date)
		}
		scrollManager.handleVisibleIDsChange(uids)
	}
	func handleTappingChanged(_ location: CGPoint) {
		guard let layout = cache.layout.layout(for: location) else { return }
		guard let viewModel = cellItems.first(where: { $0.id == layout.id }) else { return }
		setSelectedMsg(viewModel.id)
	}
	func handlePressingChanged(_ location: CGPoint?) {
		guard let location else {
			return
		}
		guard let scrollGeometry = scrollManager.scrollGeometry else {
			return
		}
		let eventY = scrollGeometry.contentOffset.y + location.y
		guard let layout = cache.layout.layout(for: .init(x: location.x, y: eventY)) else { return }
		guard let viewModel = cellItems.first(where: { $0.id == layout.id }) else { return }
		viewModel.canObserveFocusedFrame = true
	}
}

extension ChatViewManager {
	func msgCellLayoutFor(_ msg: MsgSnapshot) -> MsgCellLayout {
		guard let index = cellItems.firstIndex(where: { $0.id == msg.uid }) else { return MsgCellLayout() }
		if index > 0 && index < cellItems.count-1, let cached = cache.layout.msgCellLayout(for: msg.uid) {
			return cached
		}
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let layout = bubbleFactory.msgCellLayout(for: msg, previous: previous, next: next)
		if previous != nil && next != nil {
			cache.layout.setMsgCellLayout(layout, for: msg.uid)
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
			cache.layout.invalidateLayout()
		}
	}
}

extension ChatViewManager {

	@concurrent
	func onViewAppear() async {
		await datasource.onViewAppear()
		if await scrollManager.updatingState.hasViewLoaded {
			await viewUpdater.reloadConversation()
		} else {
			await scrollManager.setHasViewUpdated()
			Task { [weak self] in
				guard let self else { return }
				await self.viewUpdater.updateConversation()
			}
		}
	}
}

extension ChatViewManager: ScrollViewPrefetcherDelegate {

	func allIndices(for prefetcher: ScrollViewPrefetcher) -> Range<Int> {
		cellItems.indices
	}

	func prefetcher(_ prefetcher: ScrollViewPrefetcher, prefetchItemsAt indices: [Int]) {
		indices.forEach { index in
			cellItems[safe: index]?.prefetch()
		}
	}

	func prefetcher(_ prefetcher: ScrollViewPrefetcher, cancelPrefetchingFor indices: [Int]) {
		indices.forEach { index in
			cellItems[safe: index]?.cancelPrefetch()
		}
	}
}
