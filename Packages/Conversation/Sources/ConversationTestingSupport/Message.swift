import Foundation

public struct Message: Hashable, Sendable {
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
        reactions: [Reaction]
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

public enum DeliveryStatus: Int, Hashable, Sendable {
    case received
    case read
    case sending
    case delivered
    case sendingFailed
}

public struct Attachment: Hashable, Sendable {
    public init() {}
}

public struct Reaction: Hashable, Sendable {
    public init() {}
}
