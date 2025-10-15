//
//  Rounded.swift
//  XUI
//
//  Created by Aung Ko Min on 13/7/25.
//

import Foundation
import Combine

@propertyWrapper public struct Rounded<Value: FloatingPoint> {
	private var value: Value

	public let decimalPlaces: Int
	public let rule: FloatingPointRoundingRule
	private let multiplier: Value

	private let subject = PassthroughSubject<Value, Never>()

	public init(wrappedValue: Value,
				_ decimalPlaces: Int,
				rule: FloatingPointRoundingRule = .toNearestOrEven) {
		value = wrappedValue
		self.decimalPlaces = decimalPlaces
		self.rule = rule
		multiplier = Value(NSDecimalNumber(decimal: pow(10.0, decimalPlaces)).intValue)
		value = round(wrappedValue)
	}

	public var wrappedValue: Value {
		get {
			value
		}
		set {
			value = round(newValue)
			subject.send(value)
		}
	}

	public var projectedValue: AnyPublisher<Value, Never> {
		subject.eraseToAnyPublisher()
	}

	private func round(_ value: Value) -> Value {
		(value * multiplier).rounded(rule) / multiplier
	}
}
