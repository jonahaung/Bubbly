//  RMsg.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Foundation

public struct RMsg: Codable, Sendable, Hashable {
    public let uid: String
    public let conID: String
    public let senderID: String
    public let date: Date
    public let text: String?
    public var incomingStatus: DeliveryStatus
    public var outgoingStatus: MsgDeliveryState?
    public let attachments: [Attachment]?
    public let reactions: [Reaction]

    public init(
        uid: String,
        conID: String,
        senderID: String,
        date: Date,
        text: String?,
        incomingStatus: DeliveryStatus,
        outgoingStatus: MsgDeliveryState?,
        attachments: [Attachment]?,
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
            date: msg.date,
            text: msg.text,
            incomingStatus: msg.incomingStatus,
            outgoingStatus: msg.outgoingStatus,
            attachments: msg.attachments,
            reactions: msg.reactions
        )
    }
    
    public func outgoing() -> RMsg {
        var copy = self
        copy.outgoingStatus = nil
        if copy.incomingStatus == .initial {
            copy.incomingStatus = .sending
        }
        return copy
    }
}
