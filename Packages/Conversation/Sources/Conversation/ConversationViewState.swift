import Database

struct ConversationViewState: Equatable {
	let messages: [Message]
	let isLoading: Bool
	let error: String?
	let shouldDismiss: Bool
	let conversation: Conversation
	let selectedMsg: SelectedMsg?
	let overlayItem: ChatOverlayView.Item?
}
