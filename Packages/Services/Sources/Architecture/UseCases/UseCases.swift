import Combine
import Foundation

public final class SearchUsersUseCase {
	private let userRepository: UserRepositoryProtocol

	public init(userRepository: UserRepositoryProtocol) {
		self.userRepository = userRepository
	}

	public func execute() {}
}

public final class FetchMessagesUseCase {
	private let messageRepository: MessageRepositoryProtocol
	private let localStorage: LocalStorageProtocol
	private let userRepository: UserRepositoryProtocol

	public init(messageRepository: MessageRepositoryProtocol,
	            localStorage: LocalStorageProtocol,
	            userRepository: UserRepositoryProtocol)
	{
		self.messageRepository = messageRepository
		self.localStorage = localStorage
		self.userRepository = userRepository
	}

	public func execute() {}
}

public final class FetchConversationsUseCase {
	private let conversationRepository: ConversationRepositoryProtocol
	private let localStorage: LocalStorageProtocol
	private let userRepository: UserRepositoryProtocol

	public init(conversationRepository: ConversationRepositoryProtocol,
	            localStorage: LocalStorageProtocol,
	            userRepository: UserRepositoryProtocol)
	{
		self.conversationRepository = conversationRepository
		self.localStorage = localStorage
		self.userRepository = userRepository
	}

	public func execute() {}
}

public final class CreateConversationUseCase {
	private let conversationRepository: ConversationRepositoryProtocol
	private let localStorage: LocalStorageProtocol

	public init(conversationRepository: ConversationRepositoryProtocol,
	            localStorage: LocalStorageProtocol)
	{
		self.conversationRepository = conversationRepository
		self.localStorage = localStorage
	}

	public func execute() {}
}

public final class MarkConversationAsReadUseCase {
	private let conversationRepository: ConversationRepositoryProtocol
	private let localStorage: LocalStorageProtocol

	public init(conversationRepository: ConversationRepositoryProtocol,
	            localStorage: LocalStorageProtocol)
	{
		self.conversationRepository = conversationRepository
		self.localStorage = localStorage
	}

	public func execute() {}
}

public final class SearchMessagesUseCase {
	private let messageRepository: MessageRepositoryProtocol

	public init(messageRepository: MessageRepositoryProtocol) {
		self.messageRepository = messageRepository
	}

	public func execute() {}
}

public final class UploadMediaUseCase {
	private let mediaRepository: MediaRepositoryProtocol

	public init(mediaRepository: MediaRepositoryProtocol) {
		self.mediaRepository = mediaRepository
	}

	public func execute() {}
}

public final class ManageTypingIndicatorUseCase {
	private let typingRepository: TypingRepositoryProtocol
	private var typingTimer: Timer?

	public init(typingRepository: TypingRepositoryProtocol) {
		self.typingRepository = typingRepository
	}

	public func execute() {}
}

public final class UpdateUserPresenceUseCase {
	private let userRepository: UserRepositoryProtocol

	public init(userRepository: UserRepositoryProtocol) {
		self.userRepository = userRepository
	}

	public func execute() {}
}
