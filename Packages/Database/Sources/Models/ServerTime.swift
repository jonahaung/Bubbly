//
//  ServerTime.swift
//  Database
//
//  Created by Aung Ko Min on 22/8/25.
//

import Foundation

public struct ServerTime: Codable, Hashable, Sendable, Comparable {

	nonisolated(unsafe)
	public static var sgFormatter: ISO8601DateFormatter = {
		$0.formatOptions = [.withDay, .withYear, .withMonth, .withTime, .withFractionalSeconds, .withTimeZone]
		$0.timeZone = .init(abbreviation: "SGT")!
		return $0
	}(ISO8601DateFormatter())
	nonisolated(unsafe)
	public static var currentFormatterFormatter: ISO8601DateFormatter = {
		$0.formatOptions = [.withDay, .withYear, .withMonth, .withTime, .withFractionalSeconds, .withTimeZone]
		$0.timeZone = .current
		return $0
	}(ISO8601DateFormatter())

	public let value: String

	public var date: Date {
		Self.currentFormatterFormatter.date(from: value) ?? .now
	}

	public init(_ date: Date = .now) {
		value = Self.sgFormatter.string(from: date)
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
