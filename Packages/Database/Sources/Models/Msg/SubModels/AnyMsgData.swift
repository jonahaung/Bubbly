//
//  AnyMsgData.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 25/6/24.
//

import FirebaseAuth
import Foundation
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

extension AnyMsgData {
	public struct TypingStatusPayload: Sendable, Codable, Hashable {
		public let isTyping: Bool
		public let conID: String
		public let senderID: String

		public init(isTyping: Bool, conID: String, senderID: String) {
			self.isTyping = isTyping
			self.conID = conID
			self.senderID = senderID
		}
	}

	public struct ReactionPayload: Sendable, Codable, Hashable {
		public let reaction: String
		public let conID: String
		public let senderID: String

		public init(reaction: String, conID: String, senderID: String) {
			self.reaction = reaction
			self.conID = conID
			self.senderID = senderID
		}
	}

	public struct SeenStatusPayload: Sendable, Codable, Hashable {
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

extension AnyMsgData {
	public var conID: String {
		switch self {
		case .newMsg(let rMsg),
			.updatedMsg(let rMsg),
			.deleteMsg(let rMsg):
			rMsg.conID
		case .typingStatus(let typingStatus):
			typingStatus.conID
		case .reaction(let reaction):
			reaction.conID
		case .seenStatus(let status):
			status.conID
		}
	}

	public var subtitle: String {
		switch self {
		case .newMsg(let rMsg),
			.updatedMsg(let rMsg):
			rMsg.text
		case .deleteMsg(let rMsg):
			"Deleted: \(rMsg.text)"
		case .typingStatus(let typingStatus):
			typingStatus.conID
		case .reaction(let reaction):
			reaction.reaction
		case .seenStatus:
			"Seen"
		}
	}

	public func pushNotificationTitle(
		for conversation: any ConversationRepresentable
	) -> String {
		switch conversation.kind {
		case .contact:
			Auth.auth().currentUser?.displayName ?? conversation.name
		case .group(let group):
			group.name
		case .system(let ai):
			ai.name
		}
	}

	public var pushNotificationSubtitle: String {
		switch self {
		case .newMsg: "New Message"
		case .updatedMsg: "Updated"
		case .deleteMsg: "Deleted"
		case .reaction: "Reacted"
		case .typingStatus: "Typing Status"
		case .seenStatus(let status): "Has seen the \(status.msgID)"
		}
	}

	public var pushNotificationBody: String {
		switch self {
		case .newMsg(let msg),
			.updatedMsg(let msg):
			msg.text
		case .deleteMsg:
			"Message Deleted"
		case .reaction(let reaction):
			"Reacted with \(reaction.reaction)"
		case .typingStatus(let typingStatus):
			typingStatus.isTyping ? "is typing..." : "stopped typing"
		case .seenStatus(let status):
			status.msgID
		}
	}
}
