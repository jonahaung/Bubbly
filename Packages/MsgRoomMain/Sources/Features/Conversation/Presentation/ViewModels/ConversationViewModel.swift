import Combine
import Core
import Database
import Observation
import Services
import XUI

@MainActor
@Observable
public final class ConversationViewModel: @MainActor Equatable {
	public static func == (lhs: ConversationViewModel, rhs: ConversationViewModel) -> Bool {
		lhs.manager.conversation.uid == rhs.manager.conversation.uid
	}

	private(set) var state: ConversationViewState

	@ObservationIgnored
	let manager: ChatViewManager
	@ObservationIgnored
	let composer: ChatComposer
	@ObservationIgnored
	private let observeMessages: ObserveMessagesUseCase
	@ObservationIgnored
	private let sendMessage: SendMessageUseCase
	@ObservationIgnored
	private let loadMoreMessages: LoadMoreMessagesUseCase
	@ObservationIgnored
	private let retryMessage: RetryMessageUseCase
	@ObservationIgnored
	private let closeConversation: CloseConversationUseCase
	@ObservationIgnored
	private let openConversationDetails: OpenConversationDetailsUseCase
	@ObservationIgnored
	private let updateComposerSource: UpdateComposerSourceUseCase
	@ObservationIgnored
	private let appendEmoji: AppendEmojiUseCase
	@ObservationIgnored
	private let selectMessage: SelectMessageUseCase
	@ObservationIgnored
	private let openAvatar: OpenAvatarUseCase
	@ObservationIgnored
	private let markMessage: MarkMessageUseCase
	@ObservationIgnored
	private let focusMessageBubble: FocusMessageBubbleUseCase
	@ObservationIgnored
	private let sendUploadedMessage: SendUploadedMessageUseCase
	@ObservationIgnored
	private let reactToMessage: ReactToMessageUseCase
	@ObservationIgnored
	private let latestConversationSnapshot: LatestConversationSnapshotUseCase

	public init(_ prefetchedData: ConversationInitializer.PrefetchedData) {
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
			overlayItem: nil
		)
		observeManagerChanges()
	}

	deinit {
		log("Deinit")
	}

	func send(_ intent: ConversationIntent) async {
		switch intent {
		case .appear:
			await handleAppear()
		case let .sendMessage(text):
			Task { await handleSend(text) }
		case .loadMore:
			Task { await handleLoadMore() }
		case let .retry(text):
			Task { await handleRetry(text) }
		case .closeConversation:
			Task { await handleCloseConversation() }
		case .openConversationDetails:
			Task { await handleOpenConversationDetails() }
		case let .updateComposerSource(source):
			Task { await handleUpdateComposerSource(source) }
		case let .appendEmoji(emoji):
			Task { await handleAppendEmoji(emoji) }
		case let .tapMessage(uid):
			Task { await handleTapMessage(uid) }
		case let .tapAvatar(id):
			Task { await handleTapAvatar(id) }
		case let .markMessage(message):
			Task { await markMessage.execute(message) }
		case let .focusMsgBubble(item):
			Task { await handleFocusMsgBubble(item) }
		case let .uploadedAttachments(message):
			Task { await handleUploadedAttachments(message) }
		case let .react(message, reaction):
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
		state = await makeState(
			snapshot: latestConversationSnapshot.execute(),
			isLoading: false,
			error: nil,
			shouldDismiss: true
		)
		Router.shared.pop()
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
			_ = manager.layoutManager.selectedMsg
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
			overlayItem: snapshot.overlayItem
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
			overlayItem: state.overlayItem
		)
	}
}
