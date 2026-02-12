import Database

@MainActor
protocol ObserveMessagesUseCase {
	func execute() async throws -> ConversationSnapshot
}

@MainActor
protocol SendMessageUseCase {
	func execute(text: String) async throws -> ConversationSnapshot
}

@MainActor
protocol LoadMoreMessagesUseCase {
	func execute() async -> ConversationSnapshot
}

@MainActor
protocol RetryMessageUseCase {
	func execute(_ text: String) async throws -> ConversationSnapshot
}

@MainActor
protocol CloseConversationUseCase {
	func execute() async
}

@MainActor
protocol OpenConversationDetailsUseCase {
	func execute() async
}

@MainActor
protocol UpdateComposerSourceUseCase {
	func execute(_ source: ChatComposer.Source) async -> ConversationSnapshot
}

@MainActor
protocol AppendEmojiUseCase {
	func execute(_ emoji: String) async -> ConversationSnapshot
}

@MainActor
protocol SelectMessageUseCase {
	func execute(_ uid: String) async -> ConversationSnapshot
}

@MainActor
protocol OpenAvatarUseCase {
	func execute(_ id: String) async
}

@MainActor
protocol MarkMessageUseCase {
	func execute(_ message: Message) async
}

@MainActor
protocol FocusMessageBubbleUseCase {
	func execute(_ item: ChatOverlayView.Item?) async -> ConversationSnapshot
}

@MainActor
protocol SendUploadedMessageUseCase {
	func execute(_ message: Message) async -> ConversationSnapshot
}

@MainActor
protocol ReactToMessageUseCase {
	func execute(_ message: Message, _ reaction: ReactionType) async throws -> ConversationSnapshot
}

@MainActor
protocol LatestConversationSnapshotUseCase {
	func execute() async -> ConversationSnapshot
}

struct ObserveMessagesUseCaseImpl: ObserveMessagesUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute() async throws -> ConversationSnapshot {
		try await repository.observeConversation()
	}
}

struct SendMessageUseCaseImpl: SendMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(text: String) async throws -> ConversationSnapshot {
		try await repository.sendMessage(text)
	}
}

struct LoadMoreMessagesUseCaseImpl: LoadMoreMessagesUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute() async -> ConversationSnapshot {
		await repository.loadMoreMessages()
	}
}

struct RetryMessageUseCaseImpl: RetryMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ text: String) async throws -> ConversationSnapshot {
		try await repository.retryMessage(text)
	}
}

struct CloseConversationUseCaseImpl: CloseConversationUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute() async {
		await repository.closeConversation()
	}
}

struct OpenConversationDetailsUseCaseImpl: OpenConversationDetailsUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute() async {
		await repository.openConversationDetails()
	}
}

struct UpdateComposerSourceUseCaseImpl: UpdateComposerSourceUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ source: ChatComposer.Source) async -> ConversationSnapshot {
		await repository.updateComposerSource(source)
	}
}

struct AppendEmojiUseCaseImpl: AppendEmojiUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ emoji: String) async -> ConversationSnapshot {
		await repository.appendEmoji(emoji)
	}
}

struct SelectMessageUseCaseImpl: SelectMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ uid: String) async -> ConversationSnapshot {
		await repository.selectMessage(uid)
	}
}

struct OpenAvatarUseCaseImpl: OpenAvatarUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ id: String) async {
		await repository.openAvatar(for: id)
	}
}

struct MarkMessageUseCaseImpl: MarkMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ message: Message) async {
		await repository.markMessage(message)
	}
}

struct FocusMessageBubbleUseCaseImpl: FocusMessageBubbleUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ item: ChatOverlayView.Item?) async -> ConversationSnapshot {
		await repository.focusMsgBubble(item)
	}
}

struct SendUploadedMessageUseCaseImpl: SendUploadedMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ message: Message) async -> ConversationSnapshot {
		await repository.sendUploadedMessage(message)
	}
}

struct ReactToMessageUseCaseImpl: ReactToMessageUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute(_ message: Message, _ reaction: ReactionType) async throws -> ConversationSnapshot {
		try await repository.react(to: message, reaction: reaction)
	}
}

struct LatestConversationSnapshotUseCaseImpl: LatestConversationSnapshotUseCase {
	private let repository: ConversationRepository

	init(repository: ConversationRepository) {
		self.repository = repository
	}

	func execute() async -> ConversationSnapshot {
		await repository.latestSnapshot()
	}
}
