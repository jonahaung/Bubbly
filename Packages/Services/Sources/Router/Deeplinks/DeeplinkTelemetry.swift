//
//  DeeplinkTelemetry.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public struct DeeplinkTelemetry: Sendable {
	public var onParsed: @Sendable (_ url: URL, _ link: Deeplink, _ metadata: Metadata) -> Void
	public var onFailed: @Sendable (_ url: URL, _ error: DeeplinkParseError, _ metadata: Metadata)
		-> Void

	public init(onParsed: @escaping @Sendable (URL, Deeplink, Metadata) -> Void = { _, _, _ in },
	            onFailed: @escaping @Sendable (URL, DeeplinkParseError, Metadata)
	            	-> Void = { _, _, _ in })
	{
		self.onParsed = onParsed
		self.onFailed = onFailed
	}

	public struct Metadata: Sendable, Equatable {
		public var source: Source
		public var isVersioned: Bool
		public var route: String
		public var queryKeys: [String]

		public init(source: Source, isVersioned: Bool, route: String, queryKeys: [String]) {
			self.source = source
			self.isVersioned = isVersioned
			self.route = route
			self.queryKeys = queryKeys
		}

		public enum Source: Sendable, Equatable {
			case customScheme
			case universalLink
		}
	}
}

public extension DeeplinkTelemetry {
	static let `default` = DeeplinkTelemetry(
		onParsed: { url, link, _ in print("✅ \(url.absoluteString) -> \(link)") },
		onFailed: { url, err, _ in print("❌ \(url.absoluteString) \(err)") }
	)
}
