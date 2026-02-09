//
//  DeeplinkCodec.swift
//  Services
//
//  Created by Aung Ko Min on 29/1/26.
//

import Foundation

public struct DeeplinkCodec: Sendable {
	public enum URLStyle: Sendable, Equatable {
		case customScheme(version: String? = nil)
		case universalLink(host: String, version: String? = nil)
	}

	public let config: DeeplinkConfiguration
	public let aliases: DeeplinkAliases
	public let telemetry: DeeplinkTelemetry

	private let routes: [String: DeeplinkRouteDefinition<Deeplink>]

	public init(config: DeeplinkConfiguration,
	            aliases: DeeplinkAliases = .init(),
	            telemetry: DeeplinkTelemetry = .default)
	{
		self.config = config
		self.aliases = aliases
		self.telemetry = telemetry

		let defs: [DeeplinkRouteDefinition<Deeplink>] = [
			.init(
				name: "home",
				requiredQueryItems: [],
				allowedQueryItems: [],
				makeLink: { _ in .home },
				queryFromLink: { $0 == .home ? [:] : nil }
			),
			.init(
				name: "settings",
				requiredQueryItems: [],
				allowedQueryItems: [],
				makeLink: { _ in .settings },
				queryFromLink: { $0 == .settings ? [:] : nil }
			),
			.init(
				name: "profile",
				requiredQueryItems: ["id"],
				allowedQueryItems: ["id"],
				makeLink: { q in q["id"].map(Deeplink.profile(id:)) },
				queryFromLink: { link in
					if case let .profile(id) = link { return ["id": id] }
					return nil
				}
			),
			.init(
				name: "conversation",
				requiredQueryItems: ["id"],
				allowedQueryItems: ["id"],
				makeLink: { q in q["id"].map(Deeplink.conversation(id:)) },
				queryFromLink: { link in
					if case let .conversation(id) = link { return ["id": id] }
					return nil
				}
			),
		]

		routes = Dictionary(uniqueKeysWithValues: defs.map { ($0.name, $0) })
	}

	// MARK: - Build

	public func url(for link: Deeplink, style: URLStyle = .customScheme()) -> URL? {
		guard let (routeName, query) = routeAndQuery(from: link) else { return nil }

		var c = URLComponents()
		switch style {
		case let .customScheme(version):
			c.scheme = config.scheme
			if let version, config.supportedVersions.contains(version) {
				c.host = version
				c.path = "/\(routeName)"
			} else {
				c.host = routeName
			}
		case let .universalLink(host, version):
			c.scheme = "https"
			c.host = host
			if let version, config.supportedVersions.contains(version) {
				c.path = "/\(version)/\(routeName)"
			} else {
				c.path = "/\(routeName)"
			}
		}

		for (k, v) in query {
			c.setQueryItem(name: k, value: v)
		}
		return c.url
	}

	private func routeAndQuery(from link: Deeplink) -> (String, [String: String])? {
		for (name, def) in routes {
			if let q = def.queryFromLink(link) { return (name, q) }
		}
		return nil
	}

	// MARK: - Parse

	public func parse(_ url: URL) -> Result<Deeplink, DeeplinkParseError> {
		if url.scheme == config.scheme {
			return parseCustomScheme(url)
		}

		if url.scheme == "https" || url.scheme == "http",
		   let host = url.host,
		   config.universalLinkHosts.contains(host)
		{
			return parseUniversal(url)
		}

		return .failure(.unsupportedScheme(url.scheme))
	}

	private func parseCustomScheme(_ url: URL) -> Result<Deeplink, DeeplinkParseError> {
		guard let host = url.host else { return .failure(.unsupportedHost(nil)) }

		let isVersioned = config.supportedVersions.contains(host)
		let routeName: String = {
			if isVersioned { return url.pathParts.first ?? "" }
			return host
		}()

		let canonical = aliases.canonicalRoute(for: routeName)
		return finalizeParse(
			url: url,
			route: canonical,
			isVersioned: isVersioned,
			source: .customScheme
		)
	}

	private func parseUniversal(_ url: URL) -> Result<Deeplink, DeeplinkParseError> {
		let parts = url.pathParts
		let isVersioned = parts.first.map(config.supportedVersions.contains) ?? false

		let routeName: String = {
			if isVersioned { return parts.dropFirst().first ?? "" }
			return parts.first ?? "home"
		}()

		let canonical = aliases.canonicalRoute(for: routeName)
		return finalizeParse(
			url: url,
			route: canonical,
			isVersioned: isVersioned,
			source: .universalLink
		)
	}

	private func finalizeParse(url: URL,
	                           route: String,
	                           isVersioned: Bool,
	                           source: DeeplinkTelemetry.Metadata.Source) -> Result<
		Deeplink,
		DeeplinkParseError
	> {
		guard let def = routes[route] else {
			let meta = DeeplinkTelemetry.Metadata(
				source: source,
				isVersioned: isVersioned,
				route: route,
				queryKeys: queryKeys(url)
			)
			telemetry.onFailed(url, .unsupportedRoute(route), meta)
			return .failure(.unsupportedRoute(route))
		}

		let c = URLComponents(url: url, resolvingAgainstBaseURL: false)
		let items = c?.queryItems ?? []
		let query: [String: String] = Dictionary(items.compactMap {
			guard let v = $0.value else { return nil }
			return ($0.name, v)
		}, uniquingKeysWith: { $1 })

		// Strict query validation
		if config.queryValidation == .strict {
			let unknown = query.keys.filter { !def.allowedQueryItems.contains($0) }.sorted()
			if !unknown.isEmpty {
				let meta = DeeplinkTelemetry.Metadata(
					source: source,
					isVersioned: isVersioned,
					route: route,
					queryKeys: query.keys.sorted()
				)
				telemetry.onFailed(url, .unknownQueryItems(route: route, unknown: unknown), meta)
				return .failure(.unknownQueryItems(route: route, unknown: unknown))
			}
		}

		// Required params
		for key in def.requiredQueryItems {
			guard let value = query[key] else {
				let meta = DeeplinkTelemetry.Metadata(
					source: source,
					isVersioned: isVersioned,
					route: route,
					queryKeys: query.keys.sorted()
				)
				telemetry.onFailed(url, .missingRequiredParameter(route: route, name: key), meta)
				return .failure(.missingRequiredParameter(route: route, name: key))
			}
			guard !value.isEmpty else {
				let meta = DeeplinkTelemetry.Metadata(
					source: source,
					isVersioned: isVersioned,
					route: route,
					queryKeys: query.keys.sorted()
				)
				telemetry.onFailed(url, .emptyRequiredParameter(route: route, name: key), meta)
				return .failure(.emptyRequiredParameter(route: route, name: key))
			}
		}

		guard let link = def.makeLink(query) else {
			let meta = DeeplinkTelemetry.Metadata(
				source: source,
				isVersioned: isVersioned,
				route: route,
				queryKeys: query.keys.sorted()
			)
			telemetry.onFailed(url, .unsupportedRoute(route), meta)
			return .failure(.unsupportedRoute(route))
		}

		let meta = DeeplinkTelemetry.Metadata(
			source: source,
			isVersioned: isVersioned,
			route: route,
			queryKeys: query.keys.sorted()
		)
		telemetry.onParsed(url, link, meta)
		return .success(link)
	}

	private func queryKeys(_ url: URL) -> [String] {
		URLComponents(url: url, resolvingAgainstBaseURL: false)?
			.queryItems?
			.map(\.name)
			.sorted() ?? []
	}
}
