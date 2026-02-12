import Combine
import Core
import Database
import Observation
import Services

@MainActor
@Observable
final class ConversationViewModel {
	private(set) var state: ConversationViewState

	let manager: ChatViewManager
	let composer: ChatComposer

	private let observeMessages: ObserveMessagesUseCase
	private let sendMessage: SendMessageUseCase
	private let loadMoreMessages: LoadMoreMessagesUseCase
	private let retryMessage: RetryMessageUseCase
	private let closeConversation: CloseConversationUseCase
	private let openConversationDetails: OpenConversationDetailsUseCase
	private let updateComposerSource: UpdateComposerSourceUseCase
	private let appendEmoji: AppendEmojiUseCase
	private let selectMessage: SelectMessageUseCase
	private let openAvatar: OpenAvatarUseCase
	private let markMessage: MarkMessageUseCase
	private let focusMessageBubble: FocusMessageBubbleUseCase
	private let sendUploadedMessage: SendUploadedMessageUseCase
	private let reactToMessage: ReactToMessageUseCase
	private let latestConversationSnapshot: LatestConversationSnapshotUseCase

	init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
		let manager = ChatViewManager(prefetchedData)
		let composer = ChatComposer(id: prefetchedData.conversation.uid)
		let repository = ConversationRepositoryImpl(
			manager: manager,
			composer: composer,
			currentUserID: currentUserId ?? ""
		)
		self.manager = manager
		self.composer = composer
		observeMessages = ObserveMessagesUseCaseImpl(repository: repository)
		sendMessage = SendMessageUseCaseImpl(repository: repository)
		loadMoreMessages = LoadMoreMessagesUseCaseImpl(repository: repository)
		retryMessage = RetryMessageUseCaseImpl(repository: repository)
		closeConversation = CloseConversationUseCaseImpl(repository: repository)
		openConversationDetails = OpenConversationDetailsUseCaseImpl(repository: repository)
		updateComposerSource = UpdateComposerSourceUseCaseImpl(repository: repository)
		appendEmoji = AppendEmojiUseCaseImpl(repository: repository)
		selectMessage = SelectMessageUseCaseImpl(repository: repository)
		openAvatar = OpenAvatarUseCaseImpl(repository: repository)
		markMessage = MarkMessageUseCaseImpl(repository: repository)
		focusMessageBubble = FocusMessageBubbleUseCaseImpl(repository: repository)
		sendUploadedMessage = SendUploadedMessageUseCaseImpl(repository: repository)
		reactToMessage = ReactToMessageUseCaseImpl(repository: repository)
		latestConversationSnapshot = LatestConversationSnapshotUseCaseImpl(repository: repository)
		state = ConversationViewState(
			messages: prefetchedData.msgs,
			isLoading: false,
			error: nil,
			shouldDismiss: false,
			conversation: prefetchedData.conversation,
			selectedMsg: nil,
			overlayItem: nil,
			reloadID: manager.reloadID
		)
		observeManagerChanges()
	}

	func send(_ intent: ConversationIntent) {
		switch intent {
		case .appear:
			Task { await handleAppear() }
		case .sendMessage(let text):
			Task { await handleSend(text) }
		case .loadMore:
			Task { await handleLoadMore() }
		case .retry(let text):
			Task { await handleRetry(text) }
		case .closeConversation:
			Task { await handleCloseConversation() }
		case .openConversationDetails:
			Task { await handleOpenConversationDetails() }
		case .updateComposerSource(let source):
			Task { await handleUpdateComposerSource(source) }
		case .appendEmoji(let emoji):
			Task { await handleAppendEmoji(emoji) }
		case .tapMessage(let uid):
			Task { await handleTapMessage(uid) }
		case .tapAvatar(let id):
			Task { await handleTapAvatar(id) }
		case .markMessage(let message):
			Task { await markMessage.execute(message) }
		case .focusMsgBubble(let item):
			Task { await handleFocusMsgBubble(item) }
		case .uploadedAttachments(let message):
			Task { await handleUploadedAttachments(message) }
		case .react(let message, let reaction):
			Task { await handleReact(message, reaction) }
		}
	}

	private func handleAppear() async {
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await observeMessages.execute()
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await manager.showError(error)
		}
	}

	private func handleSend(_ text: String) async {
		guard text.trimmed.isEmpty == false else {
			return
		}
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await sendMessage.execute(text: text)
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await manager.showError(error)
		}
	}

	private func handleLoadMore() async {
		let snapshot = await loadMoreMessages.execute()
		state = makeState(snapshot: snapshot, isLoading: false, error: nil)
	}

	private func handleRetry(_ text: String) async {
		state = updatedState(isLoading: true, error: nil)
		do {
			let snapshot = try await retryMessage.execute(text)
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await manager.showError(error)
		}
	}

	private func handleTapMessage(_ uid: String) async {
		let snapshot = await selectMessage.execute(uid)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleCloseConversation() async {
		await closeConversation.execute()
		state = makeState(
			snapshot: await latestConversationSnapshot.execute(),
			isLoading: false,
			error: nil,
			shouldDismiss: true
		)
	}

	private func handleOpenConversationDetails() async {
		await openConversationDetails.execute()
	}

	private func handleUpdateComposerSource(_ source: ChatComposer.Source) async {
		let snapshot = await updateComposerSource.execute(source)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleAppendEmoji(_ emoji: String) async {
		let snapshot = await appendEmoji.execute(emoji)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleTapAvatar(_ id: String) async {
		await openAvatar.execute(id)
	}

	private func handleFocusMsgBubble(_ item: ChatOverlayView.Item?) async {
		let snapshot = await focusMessageBubble.execute(item)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleUploadedAttachments(_ message: Message) async {
		let snapshot = await sendUploadedMessage.execute(message)
		state = makeState(snapshot: snapshot, isLoading: false, error: state.error)
	}

	private func handleReact(_ message: Message, _ reaction: ReactionType) async {
		do {
			let snapshot = try await reactToMessage.execute(message, reaction)
			state = makeState(snapshot: snapshot, isLoading: false, error: nil)
		} catch {
			state = updatedState(isLoading: false, error: error.localizedDescription)
			await manager.showError(error)
		}
	}

	private func observeManagerChanges() {
		withObservationTracking {
			_ = manager.models.ids
			_ = manager.conversation
			_ = manager.reloadID
			_ = manager.presentation.selectedMsg
			_ = manager.presentation.overlayItem
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				let snapshot = await latestConversationSnapshot.execute()
				state = makeState(
					snapshot: snapshot,
					isLoading: state.isLoading,
					error: state.error,
					shouldDismiss: state.shouldDismiss
				)
				observeManagerChanges()
			}
		}
	}

	private func makeState(snapshot: ConversationSnapshot,
	                       isLoading: Bool,
	                       error: String?,
	                       shouldDismiss: Bool = false) -> ConversationViewState
	{
		ConversationViewState(
			messages: snapshot.messages,
			isLoading: isLoading,
			error: error,
			shouldDismiss: shouldDismiss,
			conversation: snapshot.conversation,
			selectedMsg: snapshot.selectedMsg,
			overlayItem: snapshot.overlayItem,
			reloadID: snapshot.reloadID
		)
	}

	private func updatedState(isLoading: Bool, error: String?) -> ConversationViewState {
		ConversationViewState(
			messages: state.messages,
			isLoading: isLoading,
			error: error,
			shouldDismiss: state.shouldDismiss,
			conversation: state.conversation,
			selectedMsg: state.selectedMsg,
			overlayItem: state.overlayItem,
			reloadID: state.reloadID
		)
	}
}
