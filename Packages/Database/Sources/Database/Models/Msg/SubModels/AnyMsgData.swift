//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
        public let reaction: Reaction
        public let msgID: String
        public let conID: String

        public init(reaction: Reaction, msgID: String, conID: String) {
            self.reaction = reaction
            self.msgID = msgID
            self.conID = conID
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
            rMsg.text ?? rMsg.attachments.first?.displayText ?? "New Message"
        case let .deleteMsg(rMsg):
            "Deleted: \(rMsg.uid)"
        case let .typingStatus(typingStatus):
            typingStatus.conID
        case let .reaction(reaction):
            reaction.reaction.rawValue
        case .seenStatus:
            "Seen"
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
        case let .seenStatus(status): "Has seen the \(status.msgID)"
        }
    }

    var pushNotificationBody: String {
        switch self {
        case let .newMsg(msg),
             let .updatedMsg(msg):
            msg.text ?? msg.attachments.first?.displayText ?? "New Message"
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
