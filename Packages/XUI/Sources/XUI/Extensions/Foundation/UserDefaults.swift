//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public extension UserDefaults {
    func setCodable(_ value: some Codable, forKey key: String) {
        if let data = try? JSONEncoder().encode(value) {
            set(data, forKey: key)
        }
    }

    func codable<T: Codable>(forKey key: String) -> T? {
        guard let data = data(forKey: key),
              let value = try? JSONDecoder().decode(T.self, from: data)
        else {
            return nil
        }
        return value
    }
}
