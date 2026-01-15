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
import Combine

@Observable
final class ChatViewManager: ErrorPresenter, ViewReloadable {

	let messageSource: ChatDatasource
	let scrollController: ChatScrollCoordinator
	var presentation: ChatPresentationState
	let bubbleLayout: BubbleFactory
	let conversationConfig: ConversationInitializer.Configuration
	let attachments = AttachmentFetcher()
	var reloadID: Int = 0

	var messageItems = MessagesArray()

	var conversation: Conversation {
		willSet {
			if newValue.properties.seenMembers != conversation.properties.seenMembers {
				scrollController.setDefaultAnimation(.interpolatingSpring(duration: 0.3))
			}
			layoutIfNeeded()
		}
	}

	init(_ data: ConversationInitializer.PrefetchedData) {
		conversationConfig = data.configuration
		messageSource = .init(data.configuration)
		scrollController = .init()
		presentation = .init(data.configuration)
		bubbleLayout = .init()
		conversation = data.conversation
		scrollController.coordinatorDelegate = self
		messageSource.delegate = self
		trackItemsChanges()
		reloadData(with: data.msgs, forceReset: false)
	}

	deinit {
		Log("Deinit")
	}
}

extension ChatViewManager: ChatScrollCoordinatorDelegate {

	func trackItemsChanges() {
		withObservationTracking {
			_ = messageItems.reloadID
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				scrollController.setDefaultAnimation(nil)
				layoutIfNeeded()
				trackItemsChanges()
			}
		}
	}

	var newestMessage: Database.Message? {
		messageItems.last?.msg
	}

	var oldestMessage: Database.Message? {
		messageItems.first?.msg
	}

	var canLoadOlderMessages: Bool {
		guard let firstMsgID = conversationConfig.firstMsgID else { return false }
		guard !messageItems.isEmpty else { return false }
		return !messageItems.contains(withID: firstMsgID)
	}

	var canLoadNewerMessages: Bool {
		guard let lastMsgID = conversationConfig.lastMsgID else { return false }
		guard !messageItems.isEmpty else { return false }
		return !messageItems.contains(withID: lastMsgID)
	}

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, loadOlderStartingAt message: Message) {
		coordinator.setUpdateState(.removingItems(.bottom))
		let pageSize = max(1, conversationConfig.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
		if messageItems.count >= pageSize * 2 {
			messageItems = messageItems.takingPrefix(pageSize)
		} else {
			messageItems = messageItems.takingPrefix(trimCount)
		}
		layoutIfNeeded()
		Task {
			let query = ServerTime(message.date).value
			scrollController.setUpdateState(.insertingItems(.top))
			do {
				let msgs = try await messageSource.loadPrevious(before: query, conID: message.conID)
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollController.setUpdateState(.notLoading)
				await self.showError(error)
			}
		}
	}

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, loadNewerStartingAt message: Message) {
		Task {
			let query = ServerTime(message.date).value
			do {
				let msgs = try await self.messageSource.loadMore(after: query, conID: message.conID)
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollController.setUpdateState(.notLoading)
				await self.showError(error)
			}
		}
	}

	var canResetDatasource: Bool {
		canLoadNewerMessages && !scrollController.isUserScrolling
	}

	func resetDatasource() {
		guard canResetDatasource else {
			scrollController.enqueueScroll(to: .bottom())
			return
		}
		Task {
			scrollController.setUpdateState(.resetting)
			do {
				let msgs = try await messageSource.reset(conID: conversationConfig.conID)
				reloadData(with: msgs, forceReset: true)
			} catch {
				await self.showError(error)
			}
		}
	}

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, didFinalizeUpdateAt position: ScrolledPosition) {
		presentation.bottomAccessory = position != .atBottom ? .scrollDownButton : .contactAvator
		if position == .atBottom {
			resetDatasourceIfNeeded()
		}
	}

	private func resetDatasourceIfNeeded() {
		if scrollController.updateState.isNotUpdating, !canLoadNewerMessages, messageItems.count > conversationConfig.pageSize + 5 {
			scrollController.scrollTarget = .init(edge: .bottom)
			messageItems = messageItems.takingSuffix(conversationConfig.pageSize)
		}
	}
	func reloadScrollView(for coordinator: ChatScrollCoordinator) {
		scrollController.setDefaultAnimation(nil)
		scrollController.messageLayoutCache.invalidateSizes()
		scrollController.messageLayoutCache.invalidateLayout()
		layoutIfNeeded()
	}
}

extension ChatViewManager {

	func msgCellLayoutFor(_ msg: Message, cellItems: [MsgCellViewModel]) -> MsgCellLayout {
		guard let index = cellItems.index(of: msg.uid) else { return MsgCellLayout() }
		if index > 0, index < cellItems.count - 1,
		   let cached = scrollController.messageLayoutCache.msgCellLayout(for: msg.uid) {
			return cached
		}
		let next = cellItems[safe: index + 1]?.msg
		let previous = cellItems[safe: index - 1]?.msg
		let layout = bubbleLayout.msgCellLayout(for: msg, previous: previous, next: next)
		if index > 0, index < cellItems.count - 1, previous != nil, next != nil {
			scrollController.messageLayoutCache.setMsgCellLayout(layout, for: msg.uid)
		}
		return layout
	}
}

extension ChatViewManager {

	func setSelectedMsg(_ uid: String) {
		guard let index = messageItems.index(of: uid) else { return }
		let oldValue = presentation.selectedMsg

		let nextMsg = messageItems[safe: index + 1]?.msg
		let previousMsg = messageItems[safe: index - 1]?.msg
		let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(
			id: uid,
			previous: previousMsg?.uid,
			next: nextMsg?.uid
		)
		presentation.updateSelectedMsg(newValue)
		if let oldValue {
			scrollController.messageLayoutCache.removeCache(for: oldValue.id)
			messageItems.element(withID: oldValue.id)?.layoutIfNeeded()
		}
		if let newValue {
			scrollController.messageLayoutCache.removeCache(for: newValue.id)
			let viewModel = messageItems.element(withID: newValue.id)
			viewModel?.layoutIfNeeded()
			viewModel?.animate()
		}
		scrollController.setDefaultAnimation(.interactiveSpring)
		layoutIfNeeded()
	}
}

extension ChatViewManager {

	func onViewAppear() async throws {
		scrollController.markViewAsLoaded()
		conversation = try await conversation.reload(
			refetch: !scrollController.updateState.hasViewLoaded
		)
		updateReceiveMsgs()
	}
}
