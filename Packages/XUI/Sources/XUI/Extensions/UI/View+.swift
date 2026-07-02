//  View+.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

extension View {
    @inlinable
    @ViewBuilder public func `if`(
        _ condition: Bool,
        _ transform: (Self) -> some View
    ) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @inlinable
    @ViewBuilder public func if_let<T>(
        _ optional: T?,
        _ transform: (T, Self) -> some View
    ) -> some View {
        if let optional {
            transform(optional, self)
        } else {
            self
        }
    }

    @inlinable
    public func frame(size: CGSize?) -> some View {
        frame(
            width: size.flatMap(\.width.safeFrameDimension),
            height: size.flatMap(\.height.safeFrameDimension)
        )
    }

    @inlinable
    public func frame(square: CGFloat?) -> some View {
        frame(
            width: square?.safeFrameDimension,
            height: square?.safeFrameDimension
        )
    }

    @inlinable
    public func map(_ closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}

extension CGFloat {
    /// Return nil if the value is not a valid frame dimension for SwiftUI
    public var safeFrameDimension: CGFloat? {
        guard isFinite, self >= 0 else { return nil }
        return self
    }
}

extension View {
    @inlinable
    public static var typeName: String {
        String(describing: self)
    }

    @inlinable
    public static var defaultTitle: String {
        var raw =
            String(describing: Self.self)
            .split(separator: ".")
            .last
            .map(String.init) ?? ""

        if raw.hasSuffix("View") {
            raw.removeLast(4)
        }

        return raw.reduce(into: "") { result, char in
            if result.last?.isLowercase == true, char.isUppercase {
                result.append(" ")
            }
            result.append(char)
        }
    }
}
