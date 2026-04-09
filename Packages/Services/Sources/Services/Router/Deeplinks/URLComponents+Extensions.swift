//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

extension URLComponents {
    func queryValue(_ name: String) -> String? {
        queryItems?.first(where: { $0.name == name })?.value
    }

    mutating func setQueryItem(name: String, value: String?) {
        var items = queryItems ?? []
        items.removeAll { $0.name == name }
        if let value { items.append(.init(name: name, value: value)) }
        queryItems = items.isEmpty ? nil : items
    }
}
