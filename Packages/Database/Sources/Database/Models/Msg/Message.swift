// © 2026 Aung Ko Min

//
//  MsgSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 12/7/25.
//
import Core
import CoreImage
import Foundation
import SwiftData

// MARK: - Message

public struct Message: Codable, Sendable, Hashable, UIdentifiable {
    public let uid: String
    public let senderID: String
    public let conID: String
    public var text: String?
    public let date: Date
    public var deliveryStatus: DeliveryStatus
    public var attachments: [Attachment]
    public var reactions: [Reaction]

    public init(
        uid: String,
        senderID: String,
        conID: String,
        text: String?,
        date: Date,
        deliveryStatus: DeliveryStatus,
        attachments: [Attachment],
        reactions: [Reaction],
    ) {
        self.uid = uid
        self.senderID = senderID
        self.conID = conID
        self.text = text
        self.date = date
        self.deliveryStatus = deliveryStatus
        self.attachments = attachments
        self.reactions = reactions
    }

    public init(_ rMsg: RMsg) {
        self.init(
            uid: rMsg.uid,
            senderID: rMsg.senderID,
            conID: rMsg.conID,
            text: rMsg.text,
            date: ServerTime(rMsg.date).date,
            deliveryStatus: rMsg.deliveryStatus,
            attachments: rMsg.attachments,
            reactions: rMsg.reactions,
        )
    }
}

public extension Message {
    var receiptType: MsgRecipient {
        senderID == currentUserID
            ? .outgoing
            : .incoming
    }

    var isSender: Bool {
        senderID == currentUserID
    }
}

public extension Message {
    var displayText: String {
        guard let text, !text.isWhitespace else {
            return attachments.first?.displayText ?? ""
        }

        return text
    }
}
