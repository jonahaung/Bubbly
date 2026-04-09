// © 2026 Aung Ko Min

import Foundation
import SwiftData
import UIKit

// MARK: - PMsg

@Model
public final class PMsg {
    @Attribute(.unique)
    public var uid: String
    public var senderID: String
    public var conID: String
    public var text: String? = nil
    public var date: String
    public var deliveryStatus: Int
    public var attachments: [Attachment] = []
    public var reactions: [Reaction] = []

    public init(
        uid: String,
        senderID: String,
        conID: String,
        text: String?,
        date: String,
        deliveryStatus: DeliveryStatus,
        attachments: [Attachment],
        reactions: [Reaction],
    ) {
        self.uid = uid
        self.senderID = senderID
        self.conID = conID
        self.text = text
        self.date = date
        self.deliveryStatus = deliveryStatus.rawValue
        self.attachments = attachments
        self.reactions = reactions
    }
}

public extension PMsg {
    func update(with rMsg: RMsg) {
        deliveryStatus = rMsg.deliveryStatus.rawValue
        attachments = rMsg.attachments
        reactions = rMsg.reactions
    }

    func update(from item: Message) {
        if deliveryStatus != item.deliveryStatus.rawValue {
            deliveryStatus = item.deliveryStatus.rawValue
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
            date: ServerTime(snapshot.date).value,
            deliveryStatus: snapshot.deliveryStatus,
            attachments: snapshot.attachments,
            reactions: snapshot.reactions,
        )
    }

    public func toSendable() -> Message {
        SendableType(
            uid: uid,
            senderID: senderID,
            conID: conID,
            text: text,
            date: ServerTime(date).date,
            deliveryStatus: .init(rawValue: deliveryStatus) ?? .received,
            attachments: attachments,
            reactions: reactions,
        )
    }
}
