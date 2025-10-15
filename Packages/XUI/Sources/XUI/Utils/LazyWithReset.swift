//
//  LazyWithReset.swift
//  XUI
//
//  Created by Aung Ko Min on 14/7/25.
//

import Foundation

@propertyWrapper public class LazyWithReset<Value> {
	private var value: Value?

	public let lazyInit: () -> Value

	public init(_ lazyInit: @escaping @autoclosure () -> Value) {
		self.lazyInit = lazyInit
	}

	public var wrappedValue: Value {
		get {
			if value == nil {
				value = lazyInit()
			}
			return value!
		}
	}

	public func reset() {
		value = nil
	}

	public var projectedValue: LazyWithReset<Value> {
		self
	}
}

@propertyWrapper public class BoundLazyWithReset<Receiver, Value> {
	public var receiver: Receiver?
	private var value: Value?
	public let lazyInit: (Receiver) -> Value

	public init(receiver: Receiver? = nil,
				_ lazyInit: @escaping (Receiver) -> Value) {
		self.receiver = receiver
		self.lazyInit = lazyInit
	}

	public var wrappedValue: Value {
		get {
			if value == nil {
				guard let receiver = receiver
				else {
					fatalError("Receiver not set before lazy init!")
				}
				value = lazyInit(receiver)
			}
			return value!
		}
	}

	public func reset() {
		value = nil
	}

	public var projectedValue: BoundLazyWithReset<Receiver, Value> {
		self
	}
}
