//
//  AnyEquatable.swift
//  XUI
//
//  Created by Aung Ko Min on 15/12/25.
//

import Foundation

public struct AnyEquatable: Equatable {
	public let base: Any
	private let isEqual: (_ other: Any) -> Bool

	public init<T: Equatable>(_ value: T) {
		base = value
		isEqual = { other in
			guard let other = other as? T else { return false }
			return other == value
		}
	}

	public static func == (lhs: AnyEquatable, rhs: AnyEquatable) -> Bool {
		lhs.isEqual(rhs.base)
	}
}
