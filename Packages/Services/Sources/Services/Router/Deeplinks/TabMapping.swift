// © 2026 Aung Ko Min

import Database
import Foundation

// MARK: - TabMapping

public struct TabMapping: Sendable {
    public var tabForLink: @Sendable (Deeplink) -> TabPath?

    public init(tabForLink: @escaping @Sendable (Deeplink) -> TabPath?) {
        self.tabForLink = tabForLink
    }
}

public extension TabMapping {
    static let `default` = TabMapping { link in
        switch link {
        case .home: .inbox
        case .settings: .settings
        default:
            nil
        }
    }
}

// MARK: - NavMapping

public struct NavMapping: Sendable {
    public var navForLink: @Sendable (Deeplink) -> NavPath?
    public init(navForLink: @escaping @Sendable (Deeplink) -> NavPath?) {
        self.navForLink = navForLink
    }
}

public extension NavMapping {
    static let `default` = NavMapping { link in
        switch link {
        case .conversation:
            nil
        default:
            nil
        }
    }
}
