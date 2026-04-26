//  PMsg.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import UIKit
import SwiftData
import Foundation

// MARK: - PMsg

@Model
public final class PMsg {
    @Attribute(.unique)
    public var uid: String
    public var senderID: String
    public var conID: String
    public var text: String?
    public var date: String
    public var incomingStatus: Int = 0
    public var outgoingStatus: MsgDeliveryState?
    public var deliveryStatusAggregateRaw: Int
    public var attachments: [Attachment]?
    public var reactions: [Reaction]

    public init(
        uid: String,
        senderID: String,
        conID: String,
        text: String?,
        date: String,
        incomingStatus: DeliveryStatus = .initial,
        outgoingStatus: MsgDeliveryState?,
        attachments: [Attachment]?,
        reactions: [Reaction]
    ) {
        self.uid = uid
        self.senderID = senderID
        self.conID = conID
        self.text = text
        self.date = date
        self.incomingStatus = incomingStatus.rawValue
        self.outgoingStatus = outgoingStatus
        deliveryStatusAggregateRaw = outgoingStatus?.aggregateStatus.rawValue ?? 0
        self.attachments = attachments
        self.reactions = reactions
    }
}

public extension PMsg {
    func update(with rMsg: RMsg) {
        incomingStatus = rMsg.incomingStatus.rawValue
        outgoingStatus = rMsg.outgoingStatus
        deliveryStatusAggregateRaw = outgoingStatus?.aggregateStatus.rawValue ?? 0
        attachments = rMsg.attachments
        reactions = rMsg.reactions
    }

    func update(from item: Message) {
        if outgoingStatus != item.outgoingStatus {
            outgoingStatus = item.outgoingStatus
            deliveryStatusAggregateRaw = outgoingStatus?.aggregateStatus.rawValue ?? 0
        }
        if incomingStatus != item.incomingStatus.rawValue {
            incomingStatus = item.incomingStatus.rawValue
        }
        if attachments != item.attachments {
            attachments = item.attachments
        }
        if reactions != item.reactions {
            reactions = item.reactions
        }
    }
}

// MARK: SendableTransformable

extension PMsg: SendableTransformable {
    public typealias SendableType = Message

    public convenience init(from snapshot: SendableType) {
        self.init(
            uid: snapshot.uid,
            senderID: snapshot.senderID,
            conID: snapshot.conID,
            text: snapshot.text,
            date: snapshot.serverTime.value,
            incomingStatus: snapshot.incomingStatus,
            outgoingStatus: snapshot.outgoingStatus,
            attachments: snapshot.attachments,
            reactions: snapshot.reactions
        )
    }

    public func toSendable() -> Message {
        SendableType(
            uid: uid,
            senderID: senderID,
            conID: conID,
            text: text,
            serverTime: ServerTime(date),
            incomingStatus: .init(rawValue: incomingStatus) ?? .initial,
            outgoingStatus: outgoingStatus,
            attachments: attachments,
            reactions: reactions
        )
    }
}
