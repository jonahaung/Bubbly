//  PMsg.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import UIKit
import SwiftData
import Foundation

@Model
public final class PMsg {
    @Attribute(.unique)
    public var uid: String
    public var senderID: String
    public var conID: String
    public var text: String?
    public var date: Date
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
        date: Date,
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

    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.senderID = try container.decode(String.self, forKey: .senderID)
        self.conID = try container.decode(String.self, forKey: .conID)
        self.text = try container.decodeIfPresent(String.self, forKey: .text)
        self.date = try container.decode(Date.self, forKey: .date)
        self.incomingStatus = try container.decode(Int.self, forKey: .incomingStatus)
        self.outgoingStatus = try container.decodeIfPresent(MsgDeliveryState.self, forKey: .outgoingStatus)
        self.deliveryStatusAggregateRaw = try container.decode(Int.self, forKey: .deliveryStatusAggregateRaw)
        self.attachments = try container.decodeIfPresent([Attachment].self, forKey: .attachments)
        self.reactions = try container.decode([Reaction].self, forKey: .reactions)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(senderID, forKey: .senderID)
        try container.encode(conID, forKey: .conID)
        try container.encodeIfPresent(text, forKey: .text)
        try container.encode(date, forKey: .date)
        try container.encode(incomingStatus, forKey: .incomingStatus)
        try container.encodeIfPresent(outgoingStatus, forKey: .outgoingStatus)
        try container.encode(deliveryStatusAggregateRaw, forKey: .deliveryStatusAggregateRaw)
        try container.encodeIfPresent(attachments, forKey: .attachments)
        try container.encode(reactions, forKey: .reactions)
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case senderID
        case conID
        case text
        case date
        case incomingStatus
        case outgoingStatus
        case deliveryStatusAggregateRaw
        case attachments
        case reactions
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
            date: snapshot.date,
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
            serverTime: date,
            incomingStatus: .init(rawValue: incomingStatus) ?? .initial,
            outgoingStatus: outgoingStatus,
            attachments: attachments,
            reactions: reactions
        )
    }
}
