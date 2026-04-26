//
//  AggregateDeliveryStatus.swift
//  Database
//
//  Created by Aung Ko Min on 25/4/26.
//

import XUI

public enum DeliveryStatus: Int, Sendable, Equatable, Hashable, Codable {
    case initial = 0
    case sending
    case sent
    case partiallyFailed
    case delivered
    case read
}
extension DeliveryStatus: CaseNameReflectable {}
extension DeliveryStatus: Comparable {
    public static func < (lhs: Self, rhs: Self) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}
public extension DeliveryStatus {

    var isFinal: Bool {
        self >= .delivered
    }

    var isDelivered: Bool {
        self >= .delivered
    }

    var isRead: Bool {
        self == .read
    }

    var isSending: Bool {
        self == .sending || self == .initial
    }

    var isFailure: Bool {
        self == .partiallyFailed
    }

    var canRetry: Bool {
        self == .partiallyFailed
    }
}
