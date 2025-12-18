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
	@ObservationIgnored let scrollManager: ChatScrollManager
	@ObservationIgnored var eventsManager: ChatViewEventsManager
	@ObservationIgnored let bubbleFactory: BubbleFactory
	@ObservationIgnored let config: ConversationInitializer.Configuration
	@ObservationIgnored let attachmentAPI = AttachmentDataAPI()
	@ObservationIgnored var asyncFetcher: AsyncFetcher<AttachmentData>?

	var conversation: Conversation
	var reloadID: Int = 0
	var data = MessagesArray()

	init(_ data: ConversationInitializer.PrefetchedData) {
		config = data.configuration
		datasource = .init(data.configuration)
		scrollManager = .init()
		eventsManager = .init(data.configuration)
		bubbleFactory = .init()
		conversation = data.conversation

		asyncFetcher = AsyncFetcher { [weak self] id in
			guard let self else { throw CancellationError() }
			guard let msg = await self.data.element(withID: id)?.msg else {
				throw CancellationError()
			}
			return try await attachmentAPI.fetchAttachmentData(for: msg)
		}
		scrollManager.delegate = self
		datasource.delegate = self
		trackItemsChanges()
		reloadData(with: data.msgs, forceReset: false)
	}

	deinit {
		Log("Deinit")
	}
}

extension ChatViewManager: ChatScrollManagerDelegate {

	func trackItemsChanges() {
		withObservationTracking {
			_ = data.reloadID
			_ = conversation
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				layoutIfNeeded()
				trackItemsChanges()
			}
		}
	}
	func scrollManager(reloadScrollView manager: ChatScrollManager) {
		layoutIfNeeded()
		scrollManager.layoutCache.invalidateLayout()
	}

	var lastMessage: Database.Message? {
		data.last?.msg
	}

	var firstMessage: Database.Message? {
		data.first?.msg
	}

	var canLoadPrevious: Bool {
		guard let firstMsgID = config.firstMsgID else { return false }
		guard !data.isEmpty else { return false }
		return !data.contains(withID: firstMsgID)
	}

	var canLoadMore: Bool {
		guard let lastMsgID = config.lastMsgID else { return false }
		guard !data.isEmpty else { return false }
		return !data.contains(withID: lastMsgID)
	}

	func scrollManager(_ manager: ChatScrollManager, removeItemsAt edge: VerticalEdge, itemCount: Int) {
		switch edge {
		case .top:
			data.removePrefix(itemCount)
		case .bottom:
			data.removeSuffix(itemCount)
		}
	}

	func scrollManager(_ manager: ChatScrollManager, loadPrevious msg: Message) {
		manager.updateLoadingState(.removingItems(.bottom))
		let pageSize = max(1, config.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
		if data.count >= pageSize * 2 {
			data = data.takingPrefix(pageSize)
		} else {
			data = data.takingPrefix(trimCount)
		}
		layoutIfNeeded()
		Task {
			let query = ServerTime(msg.date).value
			scrollManager.updateLoadingState(.insertingItems(.top))
			do {
				let msgs = try await datasource.loadPrevious(before: query, conID: msg.conID)
				reloadData(with: msgs, forceReset: false)
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
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollManager.updateLoadingState(.notLoading)
				await self.showError(error)
			}
		}
	}

	var canResetDatasource: Bool {
		canLoadMore && !scrollManager.isScrolling
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
				reloadData(with: msgs, forceReset: true)
			} catch {
				await self.showError(error)
			}
		}
	}

	func scrollManager(_ manager: ChatScrollManager, finalizeScrollViewUpdate position: XUI.ScrolledPosition) {
		eventsManager.canShowScrollButton = position != .atBottom
		if position == .atBottom {
			resetDatasourceIfNeeded()
		}
	}
	private func resetDatasourceIfNeeded() {
		if scrollManager.updatingState.isNotUpdating, !canLoadMore, data.count > config.pageSize + 5 {
			data = data.takingSuffix(config.pageSize)
			scrollManager.setScrollPosition(to: .init(edge: .bottom))
		}
	}
}

extension ChatViewManager {

	func msgCellLayoutFor(_ msg: Message, cellItems: [MsgCellViewModel]) -> MsgCellLayout {
		guard let index = cellItems.index(of: msg.uid) else { return MsgCellLayout() }
		if index > 0, index < cellItems.count - 1,
		   let cached = scrollManager.layoutCache.msgCellLayout(for: msg.uid) {
			return cached
		}
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let layout = bubbleFactory.msgCellLayout(for: msg, previous: previous, next: next)
		if index > 0, index < cellItems.count - 1, previous != nil, next != nil {
			scrollManager.layoutCache.setMsgCellLayout(layout, for: msg.uid)
		}
		return layout
	}
}

extension ChatViewManager {

	func setSelectedMsg(_ uid: String) {
		guard let index = data.index(of: uid) else { return }
		let oldValue = eventsManager.selectedMsg
		let nextMsg = data[safe: index + 1]?.msg
		let previousMsg = data[safe: index - 1]?.msg
		let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(id: uid, previous: previousMsg?.uid, next: nextMsg?.uid)
		eventsManager.updateSelectedMsg(newValue)
		scrollManager.layoutCache.setCache(.empty())
		layoutIfNeeded()
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
			scrollManager.setHasViewUpdated()
		}
	}
}

extension ChatViewManager {

	func handleVisibleIDsChange(_ uids: [String]) {
		let differences = uids.difference(from: scrollManager.visibleIDs)
		var inserts = [String]()
		for difference in differences {
			switch difference {
			case .insert(_, let id, _):
				if let index = data.index(of: id) {
					if let viewModel = data.element(at: index) {
						viewModel.setVisibility(true)
						//							if viewModel.msg.msgKind.shouldPrefatchData {
						//								prefetcher.onAppear(index)
						//							}
					}
				}
				inserts.append(id)
			case .remove(_, let id, _):
				if let index = data.index(of: id) {
					if let viewModel = data.element(at: index) {
						viewModel.setVisibility(false)
						//							if viewModel.msg.msgKind.shouldPrefatchData {
						//								prefetcher.onDisappear(index)
						//							}
					}
				}
			}
		}
		scrollManager.handleVisibleIDsChange(uids)
		if let uid = inserts.last,
		   let msg = data.element(withID: uid)?.msg {
			eventsManager.updateFloatingDate(msg.date)
		}
	}
}
