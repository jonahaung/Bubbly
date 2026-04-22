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
    public let date: Date

    // MARK: Initialization

    public init(_ date: Date = .now) {
        self.date = date
        value = Self.formatter.string(from: date)
    }

    public init?(_ isoString: String) {
        guard let date = Self.parse(isoString) else { return nil }
        self.date = date
        value = isoString
    }

    public static var now: ServerTime {
        .init()
    }

    // MARK: Comparable

    public static func < (lhs: ServerTime, rhs: ServerTime) -> Bool {
        lhs.date < rhs.date
    }

    // MARK: Localized Output

    public func localizedString(
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short
    ) -> String {
        Self.cachedFormatter(dateStyle: dateStyle, timeStyle: timeStyle)
            .string(from: date)
    }

    public static func localizedString(
        from value: String,
        dateStyle: DateFormatter.Style = .medium,
        timeStyle: DateFormatter.Style = .short
    ) -> String {
        guard let date = parse(value) else { return value }
        return cachedFormatter(dateStyle: dateStyle, timeStyle: timeStyle)
            .string(from: date)
    }

    // MARK: Convenience Methods

    public func timeIntervalSince(_ date: ServerTime) -> TimeInterval {
        self.date.timeIntervalSince(date.date)
    }

    public func timeIntervalSinceNow() -> TimeInterval {
        date.timeIntervalSinceNow
    }

    public func addingTimeInterval(_ interval: TimeInterval) -> ServerTime {
        ServerTime(date.addingTimeInterval(interval))
    }
}

// MARK: - Parsing

private extension ServerTime {

    static func parse(_ string: String) -> Date? {
        formatter.date(from: string)
    }

    /// Thread-safe formatter with automatic fallback handling
    nonisolated(unsafe) static let formatter: ISO8601DateFormatter = {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        formatter.timeZone = TimeZone(secondsFromGMT: 0)
        return formatter
    }()

    /// Attempts to parse with fallback if primary fails
    static func parseWithFallback(_ string: String) -> Date? {
        if let date = formatter.date(from: string) {
            return date
        }

        // Try without fractional seconds
        let fallbackFormatter = ISO8601DateFormatter()
        fallbackFormatter.formatOptions = [.withInternetDateTime]
        fallbackFormatter.timeZone = TimeZone(secondsFromGMT: 0)
        return fallbackFormatter.date(from: string)
    }
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

// MARK: - ExpressibleByStringLiteral

extension ServerTime: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        guard let serverTime = Self(value) else {
            fatalError("Invalid server time string: \(value)")
        }
        self = serverTime
    }
}

// MARK: - Convenience Extensions

public extension Date {
    var serverTime: ServerTime {
        ServerTime(self)
    }
}

public extension String {
    var serverTime: ServerTime? {
        ServerTime(self)
    }
}
