//
//  AnyMsgData.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 25/6/24.
//

import Foundation
import FirebaseAuth
import XUI

public enum AnyMsgData: Codable, Sendable, Hashable {
	case newMsg(rMsg: RMsg)
	case updatedMsg(rMsg: RMsg)
	case deleteMsg(rMsg: RMsg)
	case reaction(reaction: ReactionPayload)
	case typingStatus(status: TypingStatusPayload)
	case seenStatus(status: SeenStatusPayload)

	enum CodingKeys: String, CodingKey {
		case newMsg
		case updatedMsg
		case deleteMsg
		case reaction
		case typingStatus
		case seenStatus
	}
}
public extension AnyMsgData {

	struct TypingStatusPayload: Sendable, Codable, Hashable {
		public let isTyping: Bool
		public let conID: String
		public let senderID: String

		public init(isTyping: Bool, conID: String, senderID: String) {
			self.isTyping = isTyping
			self.conID = conID
			self.senderID = senderID
		}
	}
	struct ReactionPayload: Sendable, Codable, Hashable {
		public let reaction: String
		public let conID: String
		public let senderID: String

		public init(reaction: String, conID: String, senderID: String) {
			self.reaction = reaction
			self.conID = conID
			self.senderID = senderID
		}
	}
	struct SeenStatusPayload: Sendable, Codable, Hashable {
		public let msgID: String
		public let userID: String
		public let conID: String

		public init(msgID: String, userID: String, conID: String) {
			self.msgID = msgID
			self.userID = userID
			self.conID = conID
		}
	}
}
public extension AnyMsgData {
	var conID: String {
		switch self {
		case .newMsg(let rMsg),
				.updatedMsg(let rMsg),
				.deleteMsg(let rMsg):
			return rMsg.conID
		case .typingStatus(let typingStatus):
			return typingStatus.conID
		case .reaction(let reaction):
			return reaction.conID
		case .seenStatus(let status):
			return status.conID
		}
	}

	var subtitle: String {
		switch self {
		case .newMsg(let rMsg),
				.updatedMsg(let rMsg):
			return rMsg.text
		case .deleteMsg(let rMsg):
			return "Deleted: \(rMsg.text)"
		case .typingStatus(let typingStatus):
			return typingStatus.conID
		case .reaction(let reaction):
			return reaction.reaction
		case .seenStatus:
			return "Seen"
		}
	}
	func pushNotificationTitle(for conversation: any ConversationRepresentable) -> String {
		switch conversation.kind {
		case .contact:
			return Auth.auth().currentUser?.displayName ?? conversation.name
		case .group(let group):
			return group.name
		case .system(let ai):
			return ai.name
		}
	}

	var pushNotificationSubtitle: String {
		switch self {
		case .newMsg: return "New Message"
		case .updatedMsg: return "Updated"
		case .deleteMsg: return "Deleted"
		case .reaction: return "Reacted"
		case .typingStatus: return "Typing Status"
		case .seenStatus(let status): return "Has seen the \(status.msgID)"
		}
	}

	var pushNotificationBody: String {
		switch self {
		case .newMsg(let msg),
				.updatedMsg(let msg):
			return msg.text
		case .deleteMsg:
			return "Message Deleted"
		case .reaction(let reaction):
			return "Reacted with \(reaction.reaction)"
		case .typingStatus(let typingStatus):
			return typingStatus.isTyping ? "is typing..." : "stopped typing"
		case .seenStatus(let status):
			return status.msgID
		}
	}
}
