//
//  Then.swift
//  XUI
//
//  Created by Assistant on 16/1/26.
//

import Foundation

public protocol Then {}

public extension Then where Self: AnyObject {
	@discardableResult
	func then(_ block: (Self) -> Void) -> Self {
		block(self)
		return self
	}
}

public extension Then {
	func then(_ block: (inout Self) -> Void) -> Self {
		var copy = self
		block(&copy)
		return copy
	}
}

/// Adopt Then for all types by default.
extension NSObject: Then {}
// For value types (structs), the unconstrained extension above applies automatically.
