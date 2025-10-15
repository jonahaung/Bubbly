//
//  UserDefault.swift
//  XUI
//
//  Created by Aung Ko Min on 13/9/25.
//

import Foundation
import SwiftUI
import Combine

@MainActor
@propertyWrapper
public struct UserDefault<Value: Equatable>: DynamicProperty {
	@State private var value: Value
	let cancelBag = CancelBag()

	private let key: String
	private let defaultValue: Value
	private let container: UserDefaults

	public init(
		_ key: String = #function,
		defaultValue: Value,
		suiteName: String? = nil
	) {
		self.key = key
		self.defaultValue = defaultValue
		self.container = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard

		if let stored: Value = Self.loadValue(forKey: self.key, from: container) {
			_value = State(initialValue: stored)
		} else {
			_value = State(initialValue: defaultValue)
		}

		observeChanges()
	}

	public var wrappedValue: Value {
		get { value }
		nonmutating set {
			value = newValue
			Self.saveValue(newValue, forKey: key, in: container)
		}
	}

	public var projectedValue: Binding<Value> {
		Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
	}

	private func observeChanges() {
		NotificationCenter.default
			.publisher(for: UserDefaults.didChangeNotification, object: container)
			.sink { [container, key] _ in
				if let newValue: Value = Self.loadValue(forKey: key, from: container), newValue != value {
					value = newValue
				}
			}.store(in: cancelBag)
	}

	private static func loadValue(forKey key: String, from container: UserDefaults) -> Value? {
		switch Value.self {
		case is Int.Type: return container.integer(forKey: key) as? Value
		case is Double.Type: return container.double(forKey: key) as? Value
		case is Float.Type: return container.float(forKey: key) as? Value
		case is Bool.Type: return container.bool(forKey: key) as? Value
		case is String.Type: return container.string(forKey: key) as? Value
		case is URL.Type: return container.url(forKey: key) as? Value
		case is Data.Type: return container.data(forKey: key) as? Value
		default:
			return nil
		}
	}

	private static func saveValue(_ value: Value, forKey key: String, in container: UserDefaults) {
		switch value {
		case let v as Int: container.set(v, forKey: key)
		case let v as Double: container.set(v, forKey: key)
		case let v as Float: container.set(v, forKey: key)
		case let v as Bool: container.set(v, forKey: key)
		case let v as String: container.set(v, forKey: key)
		case let v as URL: container.set(v, forKey: key)
		case let v as Data: container.set(v, forKey: key)
		default:
			break
		}
	}
}

@MainActor
@propertyWrapper
public struct OptionalUserDefault<Value: Equatable>: DynamicProperty, Sendable {
	@State private var value: Value?
	@State private var cancellable: AnyCancellable?

	private let key: String
	private let container: UserDefaults

	public init(
		_ key: String = #function,
		suiteName: String? = nil
	) {
		self.key = key
		self.container = suiteName.flatMap { UserDefaults(suiteName: $0) } ?? .standard
		_value = State(initialValue: Self.loadValue(forKey: key, from: container))
		observeChanges()
	}

	public var wrappedValue: Value? {
		get { value }
		nonmutating set {
			value = newValue
			if let newValue {
				Self.saveValue(newValue, forKey: key, in: container)
			} else {
				container.removeObject(forKey: key)
			}
		}
	}

	public var projectedValue: Binding<Value?> {
		Binding(get: { wrappedValue }, set: { wrappedValue = $0 })
	}

	private func observeChanges() {
		cancellable = NotificationCenter.default
			.publisher(for: UserDefaults.didChangeNotification, object: container)
			.sink { [container, key] _ in
				let newValue = Self.loadValue(forKey: key, from: container)
				if newValue != value {
					value = newValue
				}
			}
	}

	private static func loadValue(forKey key: String, from container: UserDefaults) -> Value? {
		switch Value.self {
		case is Int.Type: return container.object(forKey: key) as? Value
		case is Double.Type: return container.object(forKey: key) as? Value
		case is Float.Type: return container.object(forKey: key) as? Value
		case is Bool.Type: return container.object(forKey: key) as? Value
		case is String.Type: return container.string(forKey: key) as? Value
		case is URL.Type: return container.url(forKey: key) as? Value
		case is Data.Type: return container.data(forKey: key) as? Value
		default:

			return nil
		}
	}

	private static func saveValue(_ value: Value, forKey key: String, in container: UserDefaults) {
		switch value {
		case let v as Int: container.set(v, forKey: key)
		case let v as Double: container.set(v, forKey: key)
		case let v as Float: container.set(v, forKey: key)
		case let v as Bool: container.set(v, forKey: key)
		case let v as String: container.set(v, forKey: key)
		case let v as URL: container.set(v, forKey: key)
		case let v as Data: container.set(v, forKey: key)
		default:
			break
		}
	}
}
