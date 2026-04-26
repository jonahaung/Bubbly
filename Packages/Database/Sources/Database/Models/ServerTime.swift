//  ServerTime.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

// MARK: - ServerTime

@frozen
public struct ServerTime: Codable, Hashable, Sendable, Comparable {

    // MARK: Public Properties

    public let value: String
    public var date: Date { Self.formatter.date(from: value) ?? .now }

    // MARK: Initialization

    public init(_ date: Date = .now) {
        value = Self.formatter.string(from: date)
    }

    public init(_ isoString: String) {
        value = isoString
    }

    public static var now: ServerTime {
        .init()
    }

    // MARK: Comparable

    public static func < (lhs: ServerTime, rhs: ServerTime) -> Bool {
        lhs.date < rhs.date
    }
}

// MARK: - Parsing

private extension ServerTime {
    /// Thread-safe formatter with automatic fallback handling
    nonisolated(unsafe) static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()
}

// MARK: - Cached Formatters

private extension ServerTime {

    /// Cache for localized formatters to avoid recreation
    private nonisolated(unsafe) static var formatterCache: [FormatterKey: DateFormatter] = [:]
    private static let cacheLock: NSLock = .init()

    struct FormatterKey: Hashable {
        let dateStyle: DateFormatter.Style
        let timeStyle: DateFormatter.Style
    }

    static func cachedFormatter(
        dateStyle: DateFormatter.Style,
        timeStyle: DateFormatter.Style
    ) -> DateFormatter {
        let key = FormatterKey(dateStyle: dateStyle, timeStyle: timeStyle)

        cacheLock.lock()
        defer { cacheLock.unlock() }

        if let cached = formatterCache[key] {
            return cached
        }

        let formatter = DateFormatter()
        formatter.locale = .current
        formatter.timeZone = .current
        formatter.dateStyle = dateStyle
        formatter.timeStyle = timeStyle

        formatterCache[key] = formatter
        return formatter
    }

    static func clearFormatterCache() {
        cacheLock.lock()
        defer { cacheLock.unlock() }
        formatterCache.removeAll()
    }
}

// MARK: - CustomStringConvertible

extension ServerTime: CustomStringConvertible {
    public var description: String {
        value
    }
}
