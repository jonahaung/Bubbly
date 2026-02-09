//
//  View+.swift
//
//
//  Created by Aung Ko Min on 10/6/23.
//

import SwiftUI

public extension View {
	@inlinable
	@ViewBuilder func `if`(_ condition: Bool, _ transform: (Self) -> some View) -> some View {
		if condition {
			transform(self)
		} else {
			self
		}
	}

	@inlinable
	@ViewBuilder func if_let<T>(_ optional: T?, _ transform: (T, Self) -> some View) -> some View {
		if let optional {
			transform(optional, self)
		} else {
			self
		}
	}

	@inlinable
	func frame(size: CGSize?) -> some View {
		frame(
			width: size.flatMap(\.width.safeFrameDimension),
			height: size.flatMap(\.height.safeFrameDimension)
		)
	}

	@inlinable
	func frame(square: CGFloat?) -> some View {
		frame(width: square?.safeFrameDimension, height: square?.safeFrameDimension)
	}

	@inlinable
	func map(_ closure: (inout Self) -> Void) -> Self {
		var copy = self
		closure(&copy)
		return copy
	}
}

public extension CGFloat {
	/// Return nil if the value is not a valid frame dimension for SwiftUI
	var safeFrameDimension: CGFloat? {
		guard isFinite, self >= 0 else { return nil }
		return self
	}
}

public extension View {
	@inlinable
	static var typeName: String {
		String(describing: self)
	}
}

public extension AnyView {
	@inlinable
	static var name: String {
		String(describing: self)
	}
}
