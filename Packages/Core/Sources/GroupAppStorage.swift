//  GroupAppStorage.swift
//
//  Created by Aung Ko Min on 16/6/25.
//

import Foundation
extension UserDefaults {
	nonisolated(unsafe) public static let shared = UserDefaults(suiteName: AppInformation.groupID)!
}
public struct GroupAppStorage {

	nonisolated(unsafe) public static var shared = GroupAppStorage()
	public let store = UserDefaults.shared

	private init() {}

	public func delete(for key: StorageKeys) {
		store.set(nil, forKey: key.value)
	}
	public func save(value: String?, for key: StorageKeys) {
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Int?, for key: StorageKeys) {
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Float?, for key: StorageKeys) {
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Double?, for key: StorageKeys) {
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Bool?, for key: StorageKeys) {
		store.set(value, forKey: key.value)
		store.synchronize()
	}
	public func save(value: Any?, for key: StorageKeys) {
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
