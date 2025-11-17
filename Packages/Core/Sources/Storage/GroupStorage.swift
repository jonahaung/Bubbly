//
//  GroupStorage.swift
//
//  Created by Aung Ko Min on 16/6/25.
//

import Foundation

public struct GroupStorage {
    // Shared instance that prefers the app group store, but falls back to .standard
    // in contexts where the suite is unavailable (tests, previews, misconfigured targets).
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

    // Injectable for tests or custom setups
    public init(store: UserDefaults) {
        self.store = store
    }

    // MARK: - Delete

    public func delete(for key: GroupStorageKey) {
        store.removeObject(forKey: key.value)
    }

    // MARK: - Save

    public func save(_ value: String?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    public func save(_ value: Int?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    public func save(_ value: Float?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    public func save(_ value: Double?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    public func save(_ value: Bool?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    public func save(_ value: Any?, for key: GroupStorageKey) {
        if let value { store.set(value, forKey: key.value) } else { delete(for: key) }
    }

    // MARK: - Get

    public func string(for key: GroupStorageKey) -> String? {
        store.string(forKey: key.value)
    }

    // Use object(forKey:) to preserve “missing” vs default(0/false)
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

    public func object<T>(for key: GroupStorageKey) -> T? {
        store.object(forKey: key.value) as? T
    }

    // MARK: - Requiring values

    public func requireString(for key: GroupStorageKey) throws -> String {
        if let value = string(for: key) { return value }
        throw MissingValueError(key: key)
    }

    public struct MissingValueError: Error, CustomStringConvertible {
        public let key: GroupStorageKey
        public var description: String { "Missing value for key: \(key.value)" }
    }
}
