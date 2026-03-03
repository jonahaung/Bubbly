//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public final class ExpiringCache<Key: Hashable, Value> {
    private struct Entry {
        let value: Value
        let expiry: UInt64
    }

    private var storage: [Key: Entry] = [:]

    public init() {}

    public func setValue(
        _ value: Value,
        forKey key: Key,
        expiresIn seconds: UInt64 = 60
    ) {
        let expiry = DispatchTime.now().uptimeNanoseconds + seconds * 1_000_000_000
        storage[key] = Entry(value: value, expiry: expiry)
    }

    public func value(forKey key: Key) -> Value? {
        guard let entry = storage[key] else { return nil }

        if DispatchTime.now().uptimeNanoseconds >= entry.expiry {
            storage.removeValue(forKey: key)
            return nil
        }

        return entry.value
    }
}
