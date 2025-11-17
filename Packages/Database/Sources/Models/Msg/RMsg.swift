//
//  RMsg.swift
//  Models
//
//  Created by Aung Ko Min on 25/5/25.
//

import Foundation
import XUI

public struct RMsg: Codable, Sendable, Hashable {
    public let uid: String
    public let conID: String
    public let msgKind: MsgKind
    public let senderID: String
    public let date: String
    public let text: String
    public let incomingStatus: MsgIncomingStatus
    public var outgoingStatus = [String: MsgOutgoingStatus]()
    public let attachment: Attachment?

    public init(
        uid: String,
        conID: String,
        msgKind: MsgKind,
        senderID: String,
        date: String,
        text: String,
        incomingStatus: MsgIncomingStatus,
        outgoingStatus: [String: MsgOutgoingStatus],
        attachment: Attachment?
    ) {
        self.uid = uid
        self.conID = conID
        self.msgKind = msgKind
        self.senderID = senderID
        self.date = date
        self.text = text
        self.incomingStatus = incomingStatus
        self.outgoingStatus = outgoingStatus
        self.attachment = attachment
    }

    public init(_ msg: Message) {
        self.init(
            uid: msg.uid,
            conID: msg.conID,
            msgKind: msg.msgKind,
            senderID: msg.senderID,
            date: ServerTime(msg.date).value,
            text: msg.text,
            incomingStatus: msg.incomingStatus,
            outgoingStatus: msg.outgoingStatus,
            attachment: msg.attachment
        )
    }
}
