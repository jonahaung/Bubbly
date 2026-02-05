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
final class ChatViewManager: ErrorPresenter, ViewReloadable, Equatable {

	@ObservationIgnored let messageSource: ChatDatasource
	@ObservationIgnored let scrollController: ChatScrollCoordinator
	@ObservationIgnored var presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachments = AttachmentFetcher()
	@ObservationIgnored private let id: String
	@ObservationIgnored var models: MsgModels
	private let currentUserID: String

	var reloadID: Int = 0

	var conversation: Conversation {
		willSet {
			if newValue.properties.seenMembers != conversation.properties.seenMembers {
				scrollController.setDefaultAnimation(.interpolatingSpring(duration: 0.3))
			}
			layoutIfNeeded()
		}
	}

	init(_ data: ConversationInitializer.PrefetchedData) {
		let id = data.conversation.uid
		self.id = id
		conversationConfig = data.configuration
		messageSource = .init(data.configuration)
		scrollController = .init(id: id)
		presentation = .init(data.configuration)
		conversation = data.conversation
		currentUserID = currentUserId ?? ""
		models = .init(data.msgs)
		scrollController.coordinatorDelegate = self
		messageSource.delegate = self
		trackItemsChanges()
	}

	deinit {
		log("Deinit")
	}

	nonisolated static func == (lhs: ChatViewManager, rhs: ChatViewManager) -> Bool {
		lhs.id == rhs.id
	}
}

extension ChatViewManager: ChatScrollCoordinatorDelegate {

	func trackItemsChanges() {
		withObservationTracking {
			_ = models.ids
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
		models.last?.msg
	}

	var oldestMessage: Database.Message? {
		models.first?.msg
	}

	var canLoadOlderMessages: Bool {
		guard let firstMsgID = conversationConfig.firstMsgID else { return false }
		guard !models.isEmpty else { return false }
		return !models.contains(withID: firstMsgID)
	}

	var canLoadNewerMessages: Bool {
		guard let lastMsgID = conversationConfig.lastMsgID else { return false }
		guard !models.isEmpty else { return false }
		return !models.contains(withID: lastMsgID)
	}

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, loadOlderStartingAt message: Message) {
		coordinator.setUpdateState(.removingItems(.bottom))
		let pageSize = max(1, conversationConfig.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
		if models.count >= pageSize * 2 {
			models.takingPrefix(pageSize)
		} else {
			 models.takingPrefix(trimCount)
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
		scrollController.setDefaultAnimation(nil)
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
		presentation.bottomAccessory = position != .atBottom ? .scrollDownButton : nil
		if position == .atBottom {
			resetDatasourceIfNeeded()
		}
	}

	private func resetDatasourceIfNeeded() {
		if scrollController.updateState.isNotUpdating, !canLoadNewerMessages, models.count > conversationConfig.pageSize + 5 {
			scrollController.scrollTarget = .init(edge: .bottom)
			models.takingSuffix(conversationConfig.pageSize)
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

	func setSelectedMsg(_ uid: String) {
		guard let index = models.index(of: uid) else { return }
		let oldValue = presentation.selectedMsg

		let nextMsg = models[safe: index + 1]?.msg
		let previousMsg = models[safe: index - 1]?.msg
		let newValue: SelectedMsg? = oldValue?.id == uid ? nil : SelectedMsg(
			id: uid,
			previous: previousMsg?.uid,
			next: nextMsg?.uid
		)
		presentation.updateSelectedMsg(newValue)
		if let oldValue {
			scrollController.messageLayoutCache.removeCache(for: oldValue.id)
			models.element(withID: oldValue.id)?.layoutIfNeeded()
		}
		if let newValue {
			scrollController.messageLayoutCache.removeCache(for: newValue.id)
			let viewModel = models.element(withID: newValue.id)
			viewModel?.layoutIfNeeded()
			viewModel?.animate()
		}
		scrollController.setDefaultAnimation(.interactiveSpring)
		layoutIfNeeded()
	}
}

extension ChatViewManager {

	func onViewAppear() async throws {
		conversation = try await conversation.reload(
			refetch: !scrollController.updateState.hasViewLoaded
		)
		updateReceiveMsgs()
		scrollController.markViewAsLoaded()
	}
}
