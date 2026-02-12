import Database

struct ConversationSnapshot: Equatable {
	let messages: [Message]
	let conversation: Conversation
	let selectedMsg: SelectedMsg?
	let overlayItem: ChatOverlayView.Item?
	let reloadID: Int
}

@MainActor
protocol ConversationRepository {
	func observeConversation() async throws -> ConversationSnapshot
	func sendMessage(_ text: String) async throws -> ConversationSnapshot
	func loadMoreMessages() async -> ConversationSnapshot
	func retryMessage(_ text: String) async throws -> ConversationSnapshot
	func closeConversation() async
	func openConversationDetails() async
	func updateComposerSource(_ source: ChatComposer.Source) async -> ConversationSnapshot
	func appendEmoji(_ emoji: String) async -> ConversationSnapshot
	func selectMessage(_ uid: String) async -> ConversationSnapshot
	func openAvatar(for id: String) async
	func markMessage(_ message: Message) async
	func focusMsgBubble(_ item: ChatOverlayView.Item?) async -> ConversationSnapshot
	func sendUploadedMessage(_ message: Message) async -> ConversationSnapshot
	func react(to message: Message, reaction: ReactionType) async throws -> ConversationSnapshot
	func latestSnapshot() async -> ConversationSnapshot
}
