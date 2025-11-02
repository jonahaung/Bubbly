//  GroupAppStorage.swift
//
//  Created by Aung Ko Min on 16/6/25.
//

import Foundation

public struct GroupAppStorage {

	nonisolated(unsafe)
	public static let shared = GroupAppStorage()
	public let store = UserDefaults(suiteName: AppInformation.groupID)!

	private init() {}

	public func delete(for key: StorageKeys) {
		store.set(nil, forKey: key.value)
		store.synchronize()
	}
	public func save(value: String?, for key: StorageKeys) {
		guard string(for: key) != value else { return }
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Int?, for key: StorageKeys) {
		guard integer(for: key) != value else { return }
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Float?, for key: StorageKeys) {
		guard float(for: key) != value else { return }
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Double?, for key: StorageKeys) {
		guard double(for: key) != value else { return }
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Bool?, for key: StorageKeys) {
		guard bool(for: key) != value else { return }
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Any?, for key: StorageKeys) {
		delete(for: key)
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func string(for key: StorageKeys) -> String? {
		store.string(forKey: key.value)
	}
	public func integer(for key: StorageKeys) -> Int {
		store.integer(forKey: key.value)
	}
	public func float(for key: StorageKeys) -> Float {
		store.float(forKey: key.value)
	}
	public func double(for key: StorageKeys) -> Double {
		store.double(forKey: key.value)
	}
	public func bool(for key: StorageKeys) -> Bool {
		store.bool(forKey: key.value)
	}
	public func oblect<T>(for key: StorageKeys) -> T? {
		store.object(forKey: key.value) as? T
	}
}
