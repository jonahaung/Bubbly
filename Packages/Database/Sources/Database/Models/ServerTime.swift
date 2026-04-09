// © 2026 Aung Ko Min

import Foundation

// MARK: - ServerTime

public struct ServerTime: Codable, Hashable, Sendable, Comparable {
    public let value: String

    public var date: Date {
        Self.utcFormatter.date(from: value) ?? .distantPast
    }

    public init(_ date: Date = .now) {
        value = Self.utcFormatter.string(from: date)
    }

    public init(_ isoDate: String) {
        value = isoDate
    }

    public static func < (lhs: ServerTime, rhs: ServerTime) -> Bool {
        lhs.date < rhs.date
    }
}

public extension ServerTime {
    static var now: ServerTime {
        .init(.now)
    }

    static func localizedString(from value: String) -> String {
        guard let date = utcFormatter.date(from: value) else {
            return value
        }

        return localFormatter.string(from: date)
    }
}

private extension ServerTime {
    static var utcFormatter: ISO8601DateFormatter {
        ThreadLocal.utcFormatter.value
    }

    static var localFormatter: ISO8601DateFormatter {
        ThreadLocal.localFormatter.value
    }
}

// MARK: - ThreadLocal

private enum ThreadLocal {
    private static let utcKey = "ServerTime.utcFormatter"
    private static let localKey = "ServerTime.localFormatter"

    static var utcFormatter: ThreadLocalFormatter {
        .init(key: utcKey, timeZone: .gmt)
    }

    static var localFormatter: ThreadLocalFormatter {
        .init(key: localKey, timeZone: .current)
    }
}

// MARK: - ThreadLocalFormatter

private struct ThreadLocalFormatter {
    let key: String
    let timeZone: TimeZone

    var value: ISO8601DateFormatter {
        if let existing = Thread.current.threadDictionary[key] as? ISO8601DateFormatter {
            return existing
        }
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = timeZone
        Thread.current.threadDictionary[key] = formatter
        return formatter
    }
}
