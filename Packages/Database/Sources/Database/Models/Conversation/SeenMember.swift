// © 2026 Aung Ko Min

import Foundation

// MARK: - SeenMember

public struct SeenMember: Codable, Sendable, Hashable {
    public let uid: String
    public let msgId: String
    public let date: String

    public init(uid: String, msgId: String, date: String) {
        self.uid = uid
        self.msgId = msgId
        self.date = date
    }
}

// MARK: Identifiable

extension SeenMember: Identifiable {
    public var id: String {
        uid
    }
}

// MARK: Comparable

extension SeenMember: Comparable {
    public static func < (lhs: SeenMember, rhs: SeenMember) -> Bool {
        lhs.date < rhs.date
    }
}

public extension AnyMsgData.SeenStatusPayload {
    var seenMember: SeenMember {
        .init(uid: userID, msgId: msgID, date: ServerTime.now.value)
    }
}
