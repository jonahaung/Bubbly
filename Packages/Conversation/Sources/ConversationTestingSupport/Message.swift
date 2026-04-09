// © 2026 Aung Ko Min

import Foundation

// MARK: - Message

public struct Message: Hashable, Sendable {
    public let uid: String
    public let senderID: String
    public let conID: String
    public var text: String? = nil
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
}

// MARK: - DeliveryStatus

public enum DeliveryStatus: Int, Hashable, Sendable {
    case received
    case read
    case sending
    case delivered
    case sendingFailed
}

// MARK: - Attachment

public struct Attachment: Hashable, Sendable {
    public init() {}
}

// MARK: - Reaction

public struct Reaction: Hashable, Sendable {
    public init() {}
}
