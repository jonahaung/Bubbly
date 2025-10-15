//
//  Delayed.swift
//  XUI
//
//  Created by Aung Ko Min on 13/7/25.
//

import Foundation

@propertyWrapper public struct Delayed<Value> {
	private var value: Value?

	public let failureHandler: (String) -> Never

	public init(_ failureHandler: @escaping (String) -> Never = { fatalError($0) }) {
		self.failureHandler = failureHandler
	}

	public var wrappedValue: Value {
		get {
			guard let value = value
			else {
				failureHandler("Property accessed before being initialized!")
			}
			return value
		}
		set {
			value = newValue
		}
	}

	public var projectedValue: Bool {
		value != nil
	}
}
