//
//  ServerTime.swift
//  Database
//
//  Created by Aung Ko Min on 22/8/25.
//

import Foundation

public struct ServerTime: Codable, Hashable, Sendable, Comparable {

	// Use UTC for all encoding/decoding
	nonisolated(unsafe)
	public static var utcFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		formatter.timeZone = TimeZone(secondsFromGMT: 0)
		return formatter
	}()

	// Optional — for UI/local display purposes only
	nonisolated(unsafe)
	public static var localFormatter: ISO8601DateFormatter = {
		let formatter = ISO8601DateFormatter()
		formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
		formatter.timeZone = .current
		return formatter
	}()

	public let value: String

	// Always decode using UTC (same as encoding)
	public var date: Date {
		Self.localFormatter.date(from: value) ?? .now
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
	static var now: ServerTime { .init(.now) }
}
