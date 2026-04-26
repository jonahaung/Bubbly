//  AnyMsgData.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation
import FirebaseAuth

// MARK: - AnyMsgData

public enum AnyMsgData: Codable, Sendable, Hashable {
    case newMsg(rMsg: RMsg)
    case updatedMsg(rMsg: RMsg)
    case deleteMsg(rMsg: RMsg)
    case reaction(payload: ReactionPayload)
    case typingStatus(payload: TypingStatusPayload)
    case msgRecipientReceipt(payload: MsgRecipientReceiptPayload)

    enum CodingKeys: String, CodingKey {
        case newMsg
        case updatedMsg
        case deleteMsg
        case reaction
        case typingStatus
        case msgRecipientReceipt
//        case seenStatus
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
        public let reaction: Reaction
        public let msgID: String
        public let conID: String

        public init(reaction: Reaction, msgID: String, conID: String) {
            self.reaction = reaction
            self.msgID = msgID
            self.conID = conID
        }
    }

//    struct SeenStatusPayload: Sendable, Codable, Hashable {
//        public let msgID: String
//        public let userID: String
//        public let conID: String
//        public let date: String
//
//        public init(msgID: String, userID: String, conID: String, date: String) {
//            self.msgID = msgID
//            self.userID = userID
//            self.conID = conID
//            self.date = date
//        }
//    }
    struct MsgRecipientReceiptPayload: Sendable, Codable, Hashable {
        public let msgID: String
        public let conID: String
        public let recipientReceipt: MsgRecipientReceipt
        public init(msgID: String, conID: String, recipientReceipt: MsgRecipientReceipt) {
            self.msgID = msgID
            self.conID = conID
            self.recipientReceipt = recipientReceipt
        }
    }
}

public extension AnyMsgData {
    var conID: String {
        switch self {
        case let .deleteMsg(rMsg),
             let .newMsg(rMsg),
             let .updatedMsg(rMsg):
            rMsg.conID
        case let .typingStatus(payload):
            payload.conID
        case let .reaction(payload):
            payload.conID
        case let .msgRecipientReceipt(payload):
            payload.conID
        }
    }

    var subtitle: String {
        switch self {
        case let .newMsg(rMsg),
             let .updatedMsg(rMsg):
            rMsg.text ?? rMsg.attachments?.first?.displayText ?? "New Message"
        case let .deleteMsg(rMsg):
            "Deleted: \(rMsg.uid)"
        case let .typingStatus(typingStatus):
            typingStatus.conID
        case let .reaction(reaction):
            reaction.reaction.rawValue
        case .msgRecipientReceipt(_):
            "Receipt"
        }
    }

    func pushNotificationTitle(for conversation: Conversation) -> String {
        switch conversation.kind {
        case .contact:
            Auth.auth().currentUser?.displayName ?? conversation.name
        case let .group(group):
            group.name
        }
    }

    var pushNotificationSubtitle: String {
        switch self {
        case .newMsg: "New Message"
        case .updatedMsg: "Updated"
        case .deleteMsg: "Deleted"
        case .reaction: "Reacted"
        case .typingStatus: "Typing Status"
//        case let .seenStatus(payload): "Has seen the \(payload.msgID)"
        case let .msgRecipientReceipt(payload):
            "Has seen the \(payload.recipientReceipt.status.localizedName)"
        }
    }

    var pushNotificationBody: String {
        switch self {
        case let .newMsg(msg),
             let .updatedMsg(msg):
            msg.text ?? msg.attachments?.first?.displayText ?? "New Message"
        case .deleteMsg:
            "Message Deleted"
        case let .reaction(reaction):
            "Reacted with \(reaction.reaction)"
        case let .typingStatus(typingStatus):
            typingStatus.isTyping ? "is typing..." : "stopped typing"
//        case let .seenStatus(status):
//            status.msgID
        case let .msgRecipientReceipt(payload):
            payload.preetyPrinted
        }
    }
}
