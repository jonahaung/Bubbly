// © 2026 Aung Ko Min

import Foundation

public struct DeeplinkQueryWriter: Sendable {
    private var id: String?

    public init() {}

    public mutating func set(_ key: DeeplinkQueryKey, _ value: String) {
        switch key {
        case .id:
            id = value
        }
    }

    public func apply(to components: inout URLComponents) {
        if let id {
            components.setQueryItem(name: DeeplinkQueryKey.id.rawValue, value: id)
        }
    }
}
