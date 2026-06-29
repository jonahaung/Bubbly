//  Message.swift
//
//  Copyright © 2025 Aung Ko Min.
//

//
//  MsgSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Core
import CoreImage
import SwiftData
import Foundation

// MARK: - Message

public struct Message: Codable, Sendable, Hashable, UIdentifiable {
    public let uid: String
    public var senderID: String
    public let conID: String
    public var text: String?
    public let date: Date
    public var incomingStatus: DeliveryStatus
    public var outgoingStatus: MsgDeliveryState?
    public var attachments: [Attachment]?
    public var reactions: [Reaction]
    public let isSender: Bool

    public init(
        uid: String,
        senderID: String,
        conID: String,
        text: String?,
        serverTime: Date,
        incomingStatus: DeliveryStatus,
        outgoingStatus: MsgDeliveryState?,
        attachments: [Attachment]?,
        reactions: [Reaction]
    ) {
        self.uid = uid
        self.senderID = senderID
        self.conID = conID
        self.text = text
        self.date = serverTime
        self.incomingStatus = incomingStatus
        self.outgoingStatus = outgoingStatus
        self.attachments = attachments
        self.reactions = reactions
        isSender = senderID == (try? CurrentUserID.get())
    }

    
    public init(_ rMsg: RMsg) {
       
        self.init(
            uid: rMsg.uid,
            senderID: rMsg.senderID,
            conID: rMsg.conID,
            text: rMsg.text,
            serverTime: rMsg.date,
            incomingStatus: rMsg.incomingStatus,
            outgoingStatus: rMsg.outgoingStatus,
            attachments: rMsg.attachments,
            reactions: rMsg.reactions
        )
    }
}

public extension Message {
    var receiptType: MsgRecipient {
        isSender ? .outgoing : .incoming
    }
    var deliveryStatus: DeliveryStatus? {
        isSender ? outgoingStatus?.aggregateStatus : incomingStatus
    }
}

public extension Message {
    var displayText: String {
        guard let text, !text.isWhitespace else {
            return attachments?.first?.displayText ?? ""
        }

        return text
    }
}
