// © 2026 Aung Ko Min

import Foundation

// MARK: - DeeplinkActionPlanner

public struct DeeplinkActionPlanner: Sendable {
    public var plan: @Sendable (_ link: Deeplink) -> [DeeplinkAction]
    public init(plan: @escaping @Sendable (Deeplink) -> [DeeplinkAction]) {
        self.plan = plan
    }
}

public extension DeeplinkActionPlanner {
    static func `default`(
        tabMapping: TabMapping = .default,
        navMapping: NavMapping = .default,
    ) -> DeeplinkActionPlanner {
        .init { link in
            var actions = [DeeplinkAction]()

            if let tab = tabMapping.tabForLink(link) {
                actions.append(.selectTab(tab))
            }
            if let nav = navMapping.navForLink(link) {
                actions.append(.pushToNav(nav))
            }
            switch link {
            case .home:
                actions.append(.sideEffect(.track(event: "deeplink_open_home", properties: [:])))
            case .settings:
                actions.append(.sideEffect(.track(
                    event: "deeplink_open_settings",
                    properties: [:],
                )))
            case let .profile(route):
                actions.append(.sideEffect(.prepareForContactDetails(id: route.id)))
                actions.append(.sideEffect(.track(
                    event: "deeplink_open_profile",
                    properties: ["id": route.id],
                )))
            case let .conversation(route):
                actions.append(.sideEffect(.prepareForConversation(id: route.conID)))
                actions.append(.sideEffect(.track(
                    event: "deeplink_open_conversation",
                    properties: ["id": route.conID],
                )))
            }
            return .init(actions)
        }
    }
}
