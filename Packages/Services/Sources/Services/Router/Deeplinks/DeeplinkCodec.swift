// © 2026 Aung Ko Min

import Core
import Foundation

public struct DeeplinkCodec: Sendable {
    public enum URLStyle: Sendable, Equatable {
        case customScheme(version: String? = nil)
        case universalLink(host: String, version: String? = nil)
    }

    public static let standard: DeeplinkCodec = .init(
        config: .init(
            scheme: AppInformation.urlScheme,
            supportedVersions: Set(["v1"]),
            queryValidation: .strict,
        ),
        aliases: .init(routeAliases: ["conv": .conversation]),
        telemetry: .default,
    )

    public let config: DeeplinkConfiguration
    public let aliases: DeeplinkAliases
    public let telemetry: DeeplinkTelemetry

    public init(
        config: DeeplinkConfiguration,
        aliases: DeeplinkAliases = .init(),
        telemetry: DeeplinkTelemetry = .default,
    ) {
        self.config = config
        self.aliases = aliases
        self.telemetry = telemetry
    }

    public func url(for link: Deeplink, style: URLStyle = .customScheme()) -> URL? {
        var c = URLComponents()
        switch style {
        case let .customScheme(version):
            c.scheme = config.scheme
            if let version, config.supportedVersions.contains(version) {
                c.host = version
                c.path = "/\(link.routeKind.rawValue)"
            } else {
                c.host = link.routeKind.rawValue
            }
        case let .universalLink(host, version):
            c.scheme = "https"
            c.host = host
            if let version, config.supportedVersions.contains(version) {
                c.path = "/\(version)/\(link.routeKind.rawValue)"
            } else {
                c.path = "/\(link.routeKind.rawValue)"
            }
        }

        var writer = DeeplinkQueryWriter()
        link.encodeQuery(into: &writer)
        writer.apply(to: &c)
        return c.url
    }

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
        guard let host = url.host else {
            return .failure(.unsupportedHost(nil))
        }
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? .init()
        let target = resolveRouteTarget(
            firstPart: host,
            remainingParts: url.pathParts,
            fallbackRoute: nil,
        )

        return finalizeParse(
            url: url,
            components: components,
            route: target.route,
            rawRoute: target.rawRoute,
            isVersioned: target.isVersioned,
            source: .customScheme,
        )
    }

    private func parseUniversal(_ url: URL) -> Result<Deeplink, DeeplinkParseError> {
        let components = URLComponents(url: url, resolvingAgainstBaseURL: false) ?? .init()
        let target = resolveRouteTarget(
            firstPart: nil,
            remainingParts: url.pathParts,
            fallbackRoute: Deeplink.RouteKind.home.rawValue,
        )

        return finalizeParse(
            url: url,
            components: components,
            route: target.route,
            rawRoute: target.rawRoute,
            isVersioned: target.isVersioned,
            source: .universalLink,
        )
    }

    private func finalizeParse(
        url: URL,
        components: URLComponents,
        route: Deeplink.RouteKind?,
        rawRoute: String,
        isVersioned: Bool,
        source: DeeplinkTelemetry.Metadata.Source,
    ) -> Result<
        Deeplink,
        DeeplinkParseError,
    > {
        let reader = DeeplinkQueryReader(items: components.queryItems ?? [])

        guard let route else {
            return fail(
                .unsupportedRoute(rawRoute),
                url: url,
                route: rawRoute,
                queryKeys: reader.presentKeys,
                isVersioned: isVersioned,
                source: source,
            )
        }

        if config.queryValidation == .strict {
            let unknown = reader.unknownKeys(allowedNames: route.allowedQueryKeyNames)
            if !unknown.isEmpty {
                return fail(
                    .unknownQueryItems(route: route.rawValue, unknown: unknown),
                    url: url,
                    route: route.rawValue,
                    queryKeys: reader.presentKeys,
                    isVersioned: isVersioned,
                    source: source,
                )
            }
        }

        for key in route.requiredQueryKeys {
            guard let value = reader.value(for: key) else {
                return fail(
                    .missingRequiredParameter(route: route.rawValue, name: key.rawValue),
                    url: url,
                    route: route.rawValue,
                    queryKeys: reader.presentKeys,
                    isVersioned: isVersioned,
                    source: source,
                )
            }

            guard !value.isEmpty else {
                return fail(
                    .emptyRequiredParameter(route: route.rawValue, name: key.rawValue),
                    url: url,
                    route: route.rawValue,
                    queryKeys: reader.presentKeys,
                    isVersioned: isVersioned,
                    source: source,
                )
            }
        }

        let link = route.makeLink(query: reader)

        guard let link else {
            return fail(
                .unsupportedRoute(route.rawValue),
                url: url,
                route: route.rawValue,
                queryKeys: reader.presentKeys,
                isVersioned: isVersioned,
                source: source,
            )
        }

        let meta = metadata(
            route: route.rawValue,
            queryKeys: reader.presentKeys,
            isVersioned: isVersioned,
            source: source,
        )
        telemetry.onParsed(url, link, meta)
        return .success(link)
    }

    private func resolveRouteTarget(
        firstPart: String?,
        remainingParts: [String],
        fallbackRoute: String?,
    ) -> ResolvedRouteTarget {
        var iterator = NormalizedRoutePartIterator(
            firstPart: firstPart,
            remainingParts: remainingParts,
            normalize: normalizeRouteName(_:),
        )
        let first = iterator.next() ?? fallbackRoute ?? ""
        let isVersioned = config.supportedVersions.contains(first)
        let rawRoute = isVersioned ? (iterator.next() ?? "") : first

        return .init(
            route: aliases.route(forNormalizedName: rawRoute),
            rawRoute: rawRoute,
            isVersioned: isVersioned,
        )
    }

    private func normalizeRouteName(_ value: String) -> String {
        value.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
    }

    private func metadata(
        route: String,
        queryKeys: [String],
        isVersioned: Bool,
        source: DeeplinkTelemetry.Metadata.Source,
    ) -> DeeplinkTelemetry.Metadata {
        .init(
            source: source,
            isVersioned: isVersioned,
            route: route,
            queryKeys: queryKeys,
        )
    }

    private func fail(
        _ error: DeeplinkParseError,
        url: URL,
        route: String,
        queryKeys: [String],
        isVersioned: Bool,
        source: DeeplinkTelemetry.Metadata.Source,
    ) -> Result<Deeplink, DeeplinkParseError> {
        let meta = metadata(
            route: route,
            queryKeys: queryKeys,
            isVersioned: isVersioned,
            source: source,
        )
        telemetry.onFailed(url, error, meta)
        return .failure(error)
    }

    private struct ResolvedRouteTarget: Sendable {
        let route: Deeplink.RouteKind?
        let rawRoute: String
        let isVersioned: Bool
    }

    private struct NormalizedRoutePartIterator {
        private let firstPart: String?
        private let remainingParts: [String]
        private let normalize: @Sendable (String) -> String
        private var consumedFirstPart = false
        private var nextIndex = 0

        init(
            firstPart: String?,
            remainingParts: [String],
            normalize: @escaping @Sendable (String) -> String,
        ) {
            self.firstPart = firstPart
            self.remainingParts = remainingParts
            self.normalize = normalize
        }

        mutating func next() -> String? {
            if !consumedFirstPart {
                consumedFirstPart = true

                if let firstPart {
                    let normalized = normalize(firstPart)
                    if !normalized.isEmpty {
                        return normalized
                    }
                }
            }

            while nextIndex < remainingParts.count {
                defer { nextIndex += 1 }

                let normalized = normalize(remainingParts[nextIndex])
                if !normalized.isEmpty {
                    return normalized
                }
            }

            return nil
        }
    }
}
