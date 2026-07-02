//  SeenMember.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public struct SeenMember: Codable, Sendable, Hashable {
    public let uid: String
    public let msgId: String
    public let date: Date

    public init(uid: String, msgId: String, date: Date) {
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

extension SeenMember: Comparable {
    public static func < (lhs: SeenMember, rhs: SeenMember) -> Bool {
        lhs.date < rhs.date
    }
}
