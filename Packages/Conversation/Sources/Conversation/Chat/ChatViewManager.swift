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

	struct LayoutSignature: Equatable {
		var reloadID: Int
		let selectedMsgID: String?
	}
	enum DatasourceMutation: Sendable {
		case insert(Message)
		case update(Message)
		case remove(Message)
	}
	@ObservationIgnored let messageSource: ChatDatasource
	@ObservationIgnored let scrollController: ChatScrollCoordinator
	@ObservationIgnored var presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachments = AttachmentFetcher.shared
	@ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager
	@ObservationIgnored private let currentUserID: String
	@ObservationIgnored let floatingDateThrottler = Throttler(interval: .milliseconds(200))
	@ObservationIgnored var pendingDatasourceMutations: [DatasourceMutation] = []
	@ObservationIgnored var datasourceFlushTask: Task<Void, Never>?
	@ObservationIgnored var conversation: Conversation
	@ObservationIgnored var models: MsgModels
	var reloadID: Int = 0
	var layoutSignature: LayoutSignature {
		.init(reloadID: reloadID, selectedMsgID: layoutManager.selectedMsg?.id)
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
			models.retainOldest(pageSize)
		} else {
			models.retainOldest(trimCount)
		}
		layoutIfNeeded()
		Task {
			let query = ServerTime(message.date).value
			scrollController.state.updateState = .insertingItems(.top)
			do {
				let msgs = try await messageSource.loadPrevious(before: query, conID: message.conID)
				models.prepend(msgs: msgs, preserveAnchor: message.uid)
				layoutIfNeeded()
			} catch {
				self.scrollController.state.updateState = .notUpdating
				await self.showError(error)
			}
		}
	}

	func scrollCoordinator(_: ChatScrollCoordinator,
	                       loadNewerStartingAt message: Message)
	{
		let pageSize = max(1, conversationConfig.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
		scrollController.state.updateState = .removingItems(.top)
		if models.count >= pageSize * 2 {
			models.retainNewest(pageSize)
		} else {
			models.retainNewest(trimCount)
		}
		layoutIfNeeded()
		Task {
			let query = ServerTime(message.date).value
			scrollController.state.updateState = .insertingItems(.bottom)
			do {
				let msgs = try await self.messageSource.loadMore(after: query, conID: message.conID)
				reloadData(with: msgs, forceReset: false)
			} catch {
				self.scrollController.state.updateState = .notUpdating
				await self.showError(error)
			}
		}
	}

	var canResetDatasource: Bool {
		canLoadNewerMessages && !scrollController.state.phase.isScrolling
	}

	func resetDatasource() { 
		guard canResetDatasource else {
			scrollController.enqueueScroll(to: .edge(.bottom))
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
			scrollController.performScroll(to: .snapToBottom())
			models.retainNewest(conversationConfig.pageSize)
			layoutIfNeeded()
		}
	}

	func reloadScrollView(for _: ChatScrollCoordinator) {
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
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func send(_ intent: ScrollViewIntent) {

		if case let .onScrollTargetVisibilityChange(ids) = intent {
			let differences = ids.difference(from: scrollController.state.visibleIDs)
			differences.forEach { change in
				switch change {
				case let .insert(_, element, _):
					models.element(withID: element)?.setVisibility(true)
				case let .remove(_, element, _):
					models.element(withID: element)?.layoutIfNeeded()
					models.element(withID: element)?.setVisibility(true)
				}
			}
		}

		scrollController.send(intent)
	}
	func onViewAppear() async throws {
		conversation = try await conversation.reload(
			refetch: !scrollController.state.updateState.hasViewLoaded
		)
		updateReceiveMsgs()
	}
}
