//
//  ExpiringCache.swift
//  XUI
//
//  Created by Aung Ko Min on 2/11/25.
//

import Foundation

@MainActor
public final class ExpiringCache<Value> {
	private struct Entry {
		let value: Value
		let expiry: Date
	}

	private var storage: [AnyHashable: Entry] = [:]

	public init() {}

	public func setValue(_ value: Value, forKey key: AnyHashable, expiresAt timeInterval: TimeInterval = .infinity) {
		storage[key] = Entry(value: value, expiry: .now + timeInterval)
	}

	public func value(forKey key: AnyHashable) -> Value? {
		purgeExpired(forKey: key)
		return storage[key]?.value
	}
	public func removeValue(forKey key: AnyHashable) {
		storage.removeValue(forKey: key)
	}

	private func purgeExpired(forKey key: AnyHashable) {
		if let entry = storage[key], entry.expiry <= Date() {
			storage.removeValue(forKey: key)
		}
	}
}
