import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

@MainActor
@Observable
final class ChatViewManager: ErrorPresenter, ViewReloadable {
	var reloadID: Int = 0

	@ObservationIgnored let messageSource: ChatDatasource
	@ObservationIgnored let scrollController: ChatScrollCoordinator
	@ObservationIgnored var presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachments = AttachmentFetcher()
	@ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager
	@ObservationIgnored var models: MsgModels
	private let currentUserID: String
	@ObservationIgnored let floatingDateThrottler = Throttler(interval: .milliseconds(200))

	var conversation: Conversation {
		willSet {
			if newValue.properties.seenMembers != conversation.properties.seenMembers {
				scrollController.setDefaultAnimation(.interpolatingSpring(duration: 0.3))
			}
		}
	}

	init(_ data: ConversationInitializer.PrefetchedData) {
		layoutManager = .init(cache: .init())
		conversationConfig = data.configuration
		messageSource = .init(data.configuration)
		scrollController = .init()
		presentation = .init(data.configuration)
		conversation = data.conversation
		currentUserID = currentUserId ?? ""
		models = .init(data.msgs)
		scrollController.delegate = self
		messageSource.delegate = self
	}

	deinit {
		log("Deinit")
	}
}

extension ChatViewManager: ChatScrollCoordinatorDelegate {
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

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator,
	                       loadOlderStartingAt message: Message)
	{
		coordinator.state.updateState = .removingItems(.bottom)
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
			scrollController.state.updateState = .insertingItems(.top)
			do {
				let msgs = try await messageSource.loadPrevious(before: query, conID: message.conID)
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollController.state.updateState = .notLoading
				await self.showError(error)
			}
		}
	}

	func scrollCoordinator(_: ChatScrollCoordinator,
	                       loadNewerStartingAt message: Message)
	{
		Task {
			let query = ServerTime(message.date).value
			do {
				let msgs = try await self.messageSource.loadMore(after: query, conID: message.conID)
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollController.state.updateState = .notLoading
				await self.showError(error)
			}
		}
	}

	var canResetDatasource: Bool {
		canLoadNewerMessages && !scrollController.state.phase.isScrolling
	}

	func resetDatasource() {
		scrollController.setDefaultAnimation(nil)
		guard canResetDatasource else {
			scrollController.enqueueScroll(to: .bottom())
			return
		}
		Task {
			scrollController.state.updateState = .resetting
			do {
				let msgs = try await messageSource.reset(conID: conversationConfig.conID)
				reloadData(with: msgs, forceReset: true)
			} catch {
				await self.showError(error)
			}
		}
	}

	func scrollCoordinator(_: ChatScrollCoordinator,
	                       didFinalizeUpdateAt position: ScrolledPosition)
	{
		presentation.bottomAccessory = position != .atBottom ? .scrollDownButton : nil
		if position == .atBottom {
			resetDatasourceIfNeeded()
		}
	}

	private func resetDatasourceIfNeeded() {
		if scrollController.state.updateState.isNotUpdating, !canLoadNewerMessages,
		   models.count > conversationConfig.pageSize + 5
		{
			scrollController.scrollTarget = .init(edge: .bottom)
			models.takingSuffix(conversationConfig.pageSize)
			layoutIfNeeded()
		}
	}

	func reloadScrollView(for _: ChatScrollCoordinator) {
		scrollController.setDefaultAnimation(nil)
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func setSelectedMsg(_ uid: String) {
		guard let index = models.index(of: uid) else { return }
		let oldValue = layoutManager.selectedMsg

		let nextMsg = models[safe: index + 1]?.msg
		let previousMsg = models[safe: index - 1]?.msg
		let newValue: SelectedMsg? =
			oldValue?.id == uid
				? nil
				: SelectedMsg(
					id: uid,
					previous: previousMsg?.uid,
					next: nextMsg?.uid
				)
		if let oldValue {
			layoutManager.cache.invalidate(.specificId(oldValue.id))
			models.element(withID: oldValue.id)?.layoutIfNeeded()
		}
		if let newValue {
			layoutManager.cache.invalidate(.specificId(newValue.id))
			models.element(withID: newValue.id)?.layoutIfNeeded()
		}
		layoutManager.updateSelectedMsg(newValue)
		scrollController.setDefaultAnimation(.interactiveSpring)
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func onViewAppear() async throws {
		conversation = try await conversation.reload(
			refetch: !scrollController.state.updateState.hasViewLoaded
		)
		updateReceiveMsgs()
		scrollController.markViewAsLoaded()
	}
}
