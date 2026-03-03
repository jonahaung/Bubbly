//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import XUI

public struct RMsg: Codable, Sendable, Hashable {
    public let uid: String
    public let conID: String
    public let senderID: String
    public let date: String
    public let text: String?
    public let incomingStatus: MsgIncomingStatus
    public var outgoingStatus = [String: MsgOutgoingStatus]()
    public let attachments: [Attachment]
    public let reactions: [Reaction]

    public init(
        uid: String,
        conID: String,
        senderID: String,
        date: String,
        text: String?,
        incomingStatus: MsgIncomingStatus,
        outgoingStatus: [String: MsgOutgoingStatus],
        attachments: [Attachment],
        reactions: [Reaction]
    ) {
        self.uid = uid
        self.conID = conID
        self.senderID = senderID
        self.date = date
        self.text = text
        self.incomingStatus = incomingStatus
        self.outgoingStatus = outgoingStatus
        self.attachments = attachments
        self.reactions = reactions
    }

    public init(_ msg: Message) {
        self.init(
            uid: msg.uid,
            conID: msg.conID,
            senderID: msg.senderID,
            date: ServerTime(msg.date).value,
            text: msg.text,
            incomingStatus: msg.incomingStatus,
            outgoingStatus: msg.outgoingStatus,
            attachments: msg.attachments,
            reactions: msg.reactions
        )
    }
}
