// © 2026 Aung Ko Min

import Foundation

public enum Deeplink: Hashable, Sendable {
    case home
    case profile(ProfileDeeplinkRoute)
    case conversation(ConversationDeeplinkRoute)
    case message(MessageDeepLinkRoute)
    case settings

    public enum RouteKind: String, CaseIterable, Hashable, Sendable {
        case home
        case profile
        case conversation
        case message
        case settings

        public init?(name: String) {
            self.init(rawValue: name.lowercased())
        }

        public var requiredQueryKeys: [DeeplinkQueryKey] {
            definition.requiredQueryKeys
        }

        public var allowedQueryKeys: Set<DeeplinkQueryKey> {
            definition.allowedQueryKeys
        }

        public var allowedQueryKeyNames: Set<String> {
            definition.allowedQueryKeyNames
        }

        func makeLink(query: DeeplinkQueryReader) -> Deeplink? {
            definition.makeLink(query)
        }

        private var definition: Definition {
            switch self {
            case .home:
                Self.homeDefinition
            case .profile:
                Self.profileDefinition
            case .conversation:
                Self.conversationDefinition
            case .message:
                Self.messageDefinition
            case .settings:
                Self.settingsDefinition
            }
        }

        private struct Definition: Sendable {
            let requiredQueryKeys: [DeeplinkQueryKey]
            let allowedQueryKeys: Set<DeeplinkQueryKey>
            let allowedQueryKeyNames: Set<String>
            let makeLink: @Sendable (DeeplinkQueryReader) -> Deeplink?
        }

        private static let noQueryKeys = [DeeplinkQueryKey]()
        private static let noQueryKeySet = Set<DeeplinkQueryKey>()
        private static let noQueryKeyNames = Set<String>()
        private static let idQueryKeys = [DeeplinkQueryKey.id]
        private static let idQueryKeySet: Set<DeeplinkQueryKey> = [.id]
        private static let idQueryKeyNames: Set<String> = [DeeplinkQueryKey.id.rawValue]

        private static let homeDefinition = Definition(
            requiredQueryKeys: noQueryKeys,
            allowedQueryKeys: noQueryKeySet,
            allowedQueryKeyNames: noQueryKeyNames,
            makeLink: { _ in .home },
        )

        private static let profileDefinition = Definition(
            requiredQueryKeys: idQueryKeys,
            allowedQueryKeys: idQueryKeySet,
            allowedQueryKeyNames: idQueryKeyNames,
            makeLink: { ProfileDeeplinkRoute(query: $0).map(Deeplink.profile) },
        )

        private static let conversationDefinition = Definition(
            requiredQueryKeys: idQueryKeys,
            allowedQueryKeys: idQueryKeySet,
            allowedQueryKeyNames: idQueryKeyNames,
            makeLink: { ConversationDeeplinkRoute(query: $0).map(Deeplink.conversation) },
        )

        private static let messageDefinition = Definition(
            requiredQueryKeys: idQueryKeys,
            allowedQueryKeys: idQueryKeySet,
            allowedQueryKeyNames: idQueryKeyNames,
            makeLink: { MessageDeepLinkRoute(query: $0).map(Deeplink.message) },
        )

        private static let settingsDefinition = Definition(
            requiredQueryKeys: noQueryKeys,
            allowedQueryKeys: noQueryKeySet,
            allowedQueryKeyNames: noQueryKeyNames,
            makeLink: { _ in .settings },
        )
    }

    func encodeQuery(into writer: inout DeeplinkQueryWriter) {
        switch self {
        case .home, .settings:
            break
        case let .profile(route):
            route.encode(into: &writer)
        case let .conversation(route):
            route.encode(into: &writer)
        case let .message(route):
            route.encode(into: &writer)
        }
    }

    public static func profile(id: String) -> Deeplink {
        .profile(.init(id: id))
    }

    public static func conversation(conID: String) -> Deeplink {
        .conversation(.init(conID: conID))
    }

    public static func message(msgID: String) -> Deeplink {
        .message(.init(msgID: msgID))
    }

    var routeKind: RouteKind {
        switch self {
        case .home:
            .home
        case .profile:
            .profile
        case .conversation:
            .conversation
        case .message:
            .message
        case .settings:
            .settings
        }
    }
}
