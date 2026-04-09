//
// Copyright © 2026 Aung Ko Min. All rights reserved.
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

	@inlinable
	static var defaultTitle: String {
		var raw = String(describing: Self.self)
			.split(separator: ".")
			.last
			.map(String.init) ?? ""

		if raw.hasSuffix("View") {
			raw.removeLast(4)
		}

		return raw.reduce(into: "") { result, char in
			if result.last?.isLowercase == true && char.isUppercase {
				result.append(" ")
			}
			result.append(char)
		}
	}
}

public extension AnyView {
    @inlinable
    static var name: String {
        String(describing: self)
    }
}
