// © 2026 Aung Ko Min

import Foundation

public struct DeeplinkQueryReader: Sendable {
    private let id: String?
    public let presentKeys: [String]

    public init(items: [URLQueryItem]) {
        var id: String?
        var keySet = Set<String>()

        for item in items {
            keySet.insert(item.name)

            switch item.name {
            case DeeplinkQueryKey.id.rawValue:
                id = item.value
            default:
                break
            }
        }

        self.id = id
        presentKeys = Array(keySet).sorted()
    }

    public func value(for key: DeeplinkQueryKey) -> String? {
        switch key {
        case .id:
            id
        }
    }

    public func require(_ key: DeeplinkQueryKey) -> String? {
        guard let value = value(for: key), !value.isEmpty else {
            return nil
        }
        return value
    }

    public func unknownKeys(allowedNames: Set<String>) -> [String] {
        presentKeys.filter { !allowedNames.contains($0) }
    }
}
