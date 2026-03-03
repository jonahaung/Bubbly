//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation

public struct GroupStorage {
    public nonisolated(unsafe) static let shared: GroupStorage = {
        if let defaults = UserDefaults(suiteName: AppInformation.groupID) {
            return GroupStorage(store: defaults)
        } else {
            assertionFailure(
                "UserDefaults suiteName \(AppInformation.groupID) is nil. Falling back to .standard. Check App Group entitlements for this target/scheme."
            )
            return GroupStorage(store: .standard)
        }
    }()

    public let store: UserDefaults

    /// Injectable for tests or custom setups
    public init(store: UserDefaults) {
        self.store = store
    }

    @usableFromInline
    static let defaultEncoder = JSONEncoder()
    @usableFromInline
    static let defaultDecoder = JSONDecoder()

    // MARK: - Delete

    @inlinable
    public func delete(for key: GroupStorageKey) {
        store.removeObject(forKey: key.value)
    }

    @usableFromInline
    func setOrDelete(_ value: Any?, for key: GroupStorageKey) {
        if let value {
            store.set(value, forKey: key.value)
        } else {
            delete(for: key)
        }
    }

    // MARK: - Save

    @inlinable
    public func save(_ value: String?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(_ value: Int?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(_ value: Float?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(_ value: Double?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(_ value: Bool?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(_ value: Any?, for key: GroupStorageKey) {
        setOrDelete(value, for: key)
    }

    @inlinable
    public func save(
        _ value: (some Encodable)?,
        for key: GroupStorageKey,
        encoder: JSONEncoder = GroupStorage.defaultEncoder
    ) {
        guard let value else {
            delete(for: key)
            return
        }
        do {
            let data = try encoder.encode(value)
            store.set(data, forKey: key.value)
        } catch {
            assertionFailure("Failed to encode value for key \(key.value): \(error)")
        }
    }

    // MARK: - Get

    public func string(for key: GroupStorageKey) -> String? {
        store.string(forKey: key.value)
    }

    /// Use object(forKey:) to preserve “missing” vs default(0/false)
    public func integer(for key: GroupStorageKey) -> Int? {
        store.object(forKey: key.value) as? Int
    }

    public func float(for key: GroupStorageKey) -> Float? {
        store.object(forKey: key.value) as? Float
    }

    public func double(for key: GroupStorageKey) -> Double? {
        store.object(forKey: key.value) as? Double
    }

    public func bool(for key: GroupStorageKey) -> Bool? {
        store.object(forKey: key.value) as? Bool
    }

    @inlinable
    public func data(for key: GroupStorageKey) -> Data? {
        store.data(forKey: key.value)
    }

    public func object<T>(for key: GroupStorageKey) -> T? {
        store.object(forKey: key.value) as? T
    }

    @inlinable
    public func codable<T: Decodable>(
        _ type: T.Type,
        for key: GroupStorageKey,
        decoder: JSONDecoder = GroupStorage.defaultDecoder
    ) -> T? {
        guard let data = data(for: key) else { return nil }
        do {
            return try decoder.decode(type, from: data)
        } catch {
            assertionFailure("Failed to decode value for key \(key.value): \(error)")
            return nil
        }
    }

    // MARK: - Requiring values

    public func requireString(for key: GroupStorageKey) throws -> String {
        if let value = string(for: key) { return value }
        throw MissingValueError(key: key)
    }

    @inlinable
    public func requireCodable<T: Decodable>(
        _ type: T.Type,
        for key: GroupStorageKey,
        decoder: JSONDecoder = GroupStorage
            .defaultDecoder
    ) throws -> T {
        if let value = codable(type, for: key, decoder: decoder) { return value }
        throw MissingValueError(key: key)
    }

    public struct MissingValueError: Error, CustomStringConvertible {
        public let key: GroupStorageKey

        public init(key: GroupStorageKey) {
            self.key = key
        }

        public var description: String {
            "Missing value for key: \(key.value)"
        }
    }
}
