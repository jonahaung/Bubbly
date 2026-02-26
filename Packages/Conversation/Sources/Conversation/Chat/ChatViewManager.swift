import Combine
import Core
import Database
import ImageLoader
import Services
import SwiftUI
import XUI

struct ChatViewState: Equatable {
	var reloadID: Int
	let selectedMsgID: String?
	let boundsWidth: CGFloat
	let conversation: Conversation
}

@MainActor
@Observable
final class ChatViewManager: ErrorPresenter, ViewReloadable {

	@ObservationIgnored let messageSource: ChatDatasource
	@ObservationIgnored let scrollController: ChatScrollCoordinator
	@ObservationIgnored var presentation: ChatPresentationState
	@ObservationIgnored let conversationConfig: ConversationInitializer.Configuration
	@ObservationIgnored let attachments = AttachmentFetcher.shared
	@ObservationIgnored let layoutManager: MsgsScrollViewLayoutManager
	@ObservationIgnored let debouncer = Debouncer(interval: .seconds(0.3))
	@ObservationIgnored var conversation: Conversation
	@ObservationIgnored let models: MsgModels
	@ObservationIgnored var reloadID: Int = 0
	var theme: ConversationTheme
	var state: ChatViewState

	init(_ data: ConversationInitializer.PrefetchedData) {
		state = .init(
			reloadID: 0,
			selectedMsgID: nil,
			boundsWidth: 0,
			conversation: data.conversation
		)
		layoutManager = .init(
			config: .init(
				data.configuration.lineSpacing,
				data.configuration.contentInsets,
				boundsWidth: 0
			)
		)
		conversationConfig = data.configuration
		messageSource = .init(data.configuration)
		scrollController = .init()
		presentation = .init(data.configuration)
		conversation = data.conversation
		models = .init(data.msgs)
		theme = .init(conversation)
		scrollController.delegate = self
		messageSource.delegate = self
	}

	deinit {
		log("Deinit")
	}

	func layoutIfNeeded() {
		reloadID += 1
		state = .init(
			reloadID: reloadID,
			selectedMsgID: layoutManager.selectedMsg?.id,
			boundsWidth: layoutManager.config.boundsWidth,
			conversation: conversation
		)
	}
}

extension ChatViewManager: ChatScrollCoordinatorDelegate {
	func reloadData() {
		layoutIfNeeded()
	}

	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		shouldPaginateAt edge: VerticalEdge
	) -> Bool {
		switch edge {
		case .top:
			canLoadOlderMessages
		case .bottom:
			canLoadNewerMessages
		}
	}

	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		paginateAt edge: VerticalEdge
	) {
		guard coordinator.state.updateState == .insertingItems(edge) else { return }
		switch edge {
		case .top:
			guard let oldestMessage else {
				revertState()
				return
			}
			let query = ServerTime(oldestMessage.date).value
			Task {
				do {

					let msgs = try await messageSource.loadPrevious(
						before: query,
						conID: oldestMessage.conID
					)
					await reloadData(with: msgs, forceReset: false)
				} catch {
					revertState()
					await self.showError(error)
				}
			}
		case .bottom:
			guard let newestMessage else {
				revertState()
				return
			}
			let query = ServerTime(newestMessage.date).value
			Task {
				do {
					let msgs = try await self.messageSource.loadMore(
						after: query,
						conID: newestMessage.conID
					)
					await reloadData(with: msgs, forceReset: false)
				} catch {
					revertState()
					await self.showError(error)
				}
			}
		}

		func revertState() {
			self.scrollController.state.updateState = .notUpdating
		}
	}

	func scrollCoordinator(_ coordinator: ChatScrollCoordinator, removeAt edge: VerticalEdge) {
		guard coordinator.state.updateState == .removingItems(edge) else { return }

		switch edge {
		case .top:
			let pageSize = max(1, conversationConfig.pageSize)
			let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1

			if models.count >= pageSize * 2 {
				models.retainNewest(pageSize)
			} else {
				models.retainNewest(trimCount)
			}
			layoutIfNeeded()
		case .bottom:
			let pageSize = max(1, conversationConfig.pageSize)
			let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
			if models.count >= pageSize * 2 {
				models.retainOldest(pageSize)
			} else {
				models.retainOldest(trimCount)
			}
			layoutIfNeeded()

		}
	}

	private func canRemove(at edge: VerticalEdge, trimCount: Int) -> Bool {
		let pageSize = max(1, conversationConfig.pageSize)
		let trimCount = pageSize >= 2 ? pageSize - pageSize / 2 : 1
		guard trimCount > 0 else { return false }
		guard models.count > pageSize else { return false }
		guard scrollController.state.updateState.isNotUpdating else { return false }

		switch edge {
		case .top:
			guard canLoadNewerMessages || models.count > pageSize * 2 else { return false }
		case .bottom:
			guard canLoadOlderMessages || models.count > pageSize * 2 else { return false }
		}

		let safeTrim = min(trimCount, max(0, models.count - pageSize))
		guard safeTrim > 0 else { return false }

		let removeRange: Range<Int> =
			switch edge {
			case .top:
				0..<safeTrim
			case .bottom:
				(models.count - safeTrim)..<models.count
			}

		let visible = Set(scrollController.state.visibleIDs)
		for index in removeRange {
			if let id = models[index]?.id, visible.contains(id) {
				return false
			}
		}
		return true
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

	var canResetDatasource: Bool {
		canLoadNewerMessages && scrollController.state.updateState.isNotUpdating
	}

	func resetDatasource() {
		guard canResetDatasource else {
			return
		}
		scrollController.state.updateState = .resetting
		Task {
			do {
				let msgs = try await messageSource.reset(conID: conversationConfig.conID)
				await reloadData(with: msgs, forceReset: true)
			} catch {
				await self.showError(error)
			}
		}
	}

	func handleScrollDownButtonTap() {
		if canLoadNewerMessages {
			resetDatasource()
		} else {
			scrollController.performScroll(to: .snapToBottom())
		}
	}

	func scrollCoordinator(
		_ coordinator: ChatScrollCoordinator,
		didFinalizeUpdateAt state: ScrollState
	) {
		presentation.bottomAccessory =
			state.geometry
				.isNear(.bottom) ? nil : .scrollDownButton
		if state.geometry.scrolledPosition == .atBottom {
			resetDatasourceIfNeeded()
		}
	}

	private func resetDatasourceIfNeeded() {
		if scrollController.state.updateState.isNotUpdating, !canLoadNewerMessages,
			models.count > conversationConfig.pageSize + 5
		{
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
			models.element(withID: oldValue.id)?.layoutIfNeeded()
		}
		if let newValue {
			models.element(withID: newValue.id)?.layoutIfNeeded()
		}
		layoutManager.updateSelectedMsg(newValue)
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func send(_ intent: ScrollViewIntent) {

		if case .onScrollTargetVisibilityChange(let ids) = intent {
			Task {
				await debouncer.run { [weak self] in
					guard let self else { return }
					await MainActor.run { [weak self] in
						guard let self else { return }
						let oldIDs = scrollController.state.visibleIDs
						let differences = ids.difference(from: oldIDs)
						differences.forEach { change in
							switch change {
							case .insert(_, let element, _):
								self.models.didChangeVisibility(for: element, isVisible: true)

							case .remove(_, let element, _):
								self.models.didChangeVisibility(for: element, isVisible: false)

							}
						}
						scrollController.send(.onScrollTargetVisibilityChange(ids))
					}
				}
			}
		} else {
			scrollController.send(intent)
		}
	}
	func onViewAppear() async throws {
		conversation = try await conversation.reload(
			refetch: !scrollController.state.updateState.hasViewLoaded
		)
		theme = .init(conversation)
		updateReceiveMsgs()
	}
}
