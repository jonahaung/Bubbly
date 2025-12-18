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
        case let .newMsg(rMsg),
             let .updatedMsg(rMsg),
             let .deleteMsg(rMsg):
            rMsg.conID
        case let .typingStatus(typingStatus):
            typingStatus.conID
        case let .reaction(reaction):
            reaction.conID
        case let .seenStatus(status):
            status.conID
        }
    }

    var subtitle: String {
        switch self {
        case let .newMsg(rMsg),
             let .updatedMsg(rMsg):
            rMsg.text
        case let .deleteMsg(rMsg):
            "Deleted: \(rMsg.text)"
        case let .typingStatus(typingStatus):
            typingStatus.conID
        case let .reaction(reaction):
            reaction.reaction
        case .seenStatus:
            "Seen"
        }
    }

    func pushNotificationTitle(
		for conversation: Conversation
    ) -> String {
        switch conversation.kind {
        case .contact:
            Auth.auth().currentUser?.displayName ?? conversation.name
        case let .group(group):
            group.name
        case let .system(ai):
            ai.name
        }
    }

    var pushNotificationSubtitle: String {
        switch self {
        case .newMsg: "New Message"
        case .updatedMsg: "Updated"
        case .deleteMsg: "Deleted"
        case .reaction: "Reacted"
        case .typingStatus: "Typing Status"
        case let .seenStatus(status): "Has seen the \(status.msgID)"
        }
    }

    var pushNotificationBody: String {
        switch self {
        case let .newMsg(msg),
             let .updatedMsg(msg):
            msg.text
        case .deleteMsg:
            "Message Deleted"
        case let .reaction(reaction):
            "Reacted with \(reaction.reaction)"
        case let .typingStatus(typingStatus):
            typingStatus.isTyping ? "is typing..." : "stopped typing"
        case let .seenStatus(status):
            status.msgID
        }
    }
}
