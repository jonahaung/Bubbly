import Database

enum ConversationIntent {
	case appear
	case sendMessage(String)
	case loadMore
	case retry(String)
	case closeConversation
	case openConversationDetails
	case updateComposerSource(ChatComposer.Source)
	case appendEmoji(String)
	case tapMessage(String)
	case tapAvatar(String)
	case markMessage(Message)
	case focusMsgBubble(ChatOverlayView.Item?)
	case uploadedAttachments(Message)
	case react(Message, ReactionType)
}
