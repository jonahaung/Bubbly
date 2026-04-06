//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import SwiftData
import UIKit

@Model
public final class PMsg {
    @Attribute(.unique)
    public var uid = String()
    public var senderID = String()
    public var conID = String()
    public var text: String?
    public var date = String()
	public var deliveryStatus: Int
    public var attachments = [Attachment]()
    public var reactions = [Reaction]()

    public init(
        uid: String,
        senderID: String,
        conID: String,
        text: String?,
        date: String,
        deliveryStatus: DeliveryStatus,
        attachments: [Attachment],
        reactions: [Reaction]
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
        deliveryStatus = item.deliveryStatus.rawValue
        attachments = item.attachments
        reactions = item.reactions
    }
}

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
            reactions: snapshot.reactions
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
            reactions: reactions
        )
    }
}
