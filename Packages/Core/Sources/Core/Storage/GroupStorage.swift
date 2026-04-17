// © 2026 Aung Ko Min

import Foundation

public struct StorageKey<Value>: Sendable {
    public let name: String

    public init(_ name: String) {
        self.name = name
    }
}

private protocol _UserDefaultsPrimitive {}

extension String: _UserDefaultsPrimitive {}
extension Int: _UserDefaultsPrimitive {}
extension Bool: _UserDefaultsPrimitive {}
extension Double: _UserDefaultsPrimitive {}
extension Float: _UserDefaultsPrimitive {}
extension Data: _UserDefaultsPrimitive {}
extension Date: _UserDefaultsPrimitive {}

public struct GroupStorage: @unchecked Sendable {
    public static let shared: GroupStorage = {
        if let defaults = UserDefaults(suiteName: AppInformation.groupID) {
            return GroupStorage(store: defaults)
        }
        return GroupStorage(store: .standard)
    }()

    public let store: UserDefaults
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(
        store: UserDefaults,
        encoder: JSONEncoder = .init(),
        decoder: JSONDecoder = .init()
    ) {
        self.store = store
        self.encoder = encoder
        self.decoder = decoder
    }
}

public extension GroupStorage {
    func set<Value: Encodable>(
        _ value: Value?,
        for key: StorageKey<Value>
    ) {
        guard let value else {
            store.removeObject(forKey: key.name)
            return
        }

        if let primitive = value as? any _UserDefaultsPrimitive {
            store.set(primitive, forKey: key.name)
            return
        }

        do {
            let data = try encoder.encode(value)
            store.set(data, forKey: key.name)
        } catch {
            store.removeObject(forKey: key.name)
        }
    }

    func get<Value: Decodable>(
        _ key: StorageKey<Value>
    ) -> Value? {
        if Value.self is any _UserDefaultsPrimitive.Type {
            return store.object(forKey: key.name) as? Value
        }

        guard let data = store.data(forKey: key.name) else {
            return nil
        }

        do {
            return try decoder.decode(Value.self, from: data)
        } catch {
            return nil
        }
    }

    func require<Value: Decodable>(
        _ key: StorageKey<Value>
    ) throws -> Value {
        if let value = get(key) {
            return value
        }
        throw MissingValueError(key: key.name)
    }

    func delete<Value>(
        _ key: StorageKey<Value>
    ) {
        store.removeObject(forKey: key.name)
    }
}

public extension GroupStorage {
    func save<Value: Encodable>(
        _ value: Value?,
        for key: GroupStorageKey
    ) {
        let storageKey = StorageKey<Value>(key.value)
        set(value, for: storageKey)
    }

    func codable<Value: Decodable>(
        _ type: Value.Type,
        for key: GroupStorageKey
    ) -> Value? {
        let storageKey = StorageKey<Value>(key.value)
        return get(storageKey)
    }

    func string(for key: GroupStorageKey) -> String? {
        store.string(forKey: key.value)
    }

    func integer(for key: GroupStorageKey) -> Int? {
        guard store.object(forKey: key.value) != nil else {
            return nil
        }
        return store.integer(forKey: key.value)
    }

    func bool(for key: GroupStorageKey) -> Bool? {
        guard store.object(forKey: key.value) != nil else {
            return nil
        }
        return store.bool(forKey: key.value)
    }

    func double(for key: GroupStorageKey) -> Double? {
        guard store.object(forKey: key.value) != nil else {
            return nil
        }
        return store.double(forKey: key.value)
    }

    func data(for key: GroupStorageKey) -> Data? {
        store.data(forKey: key.value)
    }

    func delete(for key: GroupStorageKey) {
        store.removeObject(forKey: key.value)
    }
}

public extension GroupStorage {
    struct MissingValueError: Error, CustomStringConvertible {
        public let key: String

        public var description: String {
            "Missing value for key: \(key)"
        }
    }
}

public actor GroupStorageActor {
    private let storage: GroupStorage

    public init(storage: GroupStorage = .shared) {
        self.storage = storage
    }

    public func get<Value: Decodable>(_ key: StorageKey<Value>) -> Value? {
        storage.get(key)
    }

    public func set<Value: Encodable>(_ value: Value?, for key: StorageKey<Value>) {
        storage.set(value, for: key)
    }

    public func save<Value: Encodable>(_ value: Value?, for key: GroupStorageKey) {
        storage.save(value, for: key)
    }

    public func delete<Value>(_ key: StorageKey<Value>) {
        storage.delete(key)
    }

    public func delete(for key: GroupStorageKey) {
        storage.delete(for: key)
    }
}
