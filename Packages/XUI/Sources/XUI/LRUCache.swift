//  LRUCache.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation

public final class LRUCache<Key: Hashable, Value> {

    private var storage: [Key: Value] = [:]

    public init() {}
    // MARK: Public API

    public var count: Int {
        storage.count
    }

    public func get(_ key: Key) -> Value? {
        storage[key]
    }

    public func set(_ key: Key, value: Value) {
        storage[key] = value
    }

    public func remove(_ key: Key) {
        storage[key] = nil
    }

    public func removeAll() {
        storage.removeAll()
    }
}

//public final class DicCache<Key: Hashable, Value>: @unchecked Sendable {
//	private var dict: [Key: Value] = [:]
//
//	public init() {
//	}
//
//	public func get(_ key: Key) -> Value? {
//		dict[key]
//	}
//
//	public func set(_ key: Key, value: Value) {
//		dict[key] = value
//	}
//
//	public func remove(_ key: Key) {
//		dict[key] = nil
//	}
//
//	public func removeAll() {
//		dict.removeAll()
//	}
//}
