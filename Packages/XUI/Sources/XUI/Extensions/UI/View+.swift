//
//  View+.swift
//
//
//  Created by Aung Ko Min on 10/6/23.
//

import SwiftUI

public extension View {
    @ViewBuilder func `if`(_ condition: Bool, _ transform: (Self) -> some View) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder func if_let<T>(_ optional: T?, _ transform: (T, Self) -> some View) -> some View {
        if let optional {
            transform(optional, self)
        } else {
            self
        }
    }

    @inlinable
    func frame(size: CGSize?) -> some View {
        frame(width: size?.width, height: size?.height)
    }

    @inlinable
    func frame(square: CGFloat?) -> some View {
        frame(width: square, height: square)
    }

    @inlinable
    func map(_ closure: (inout Self) -> Void) -> Self {
        var copy = self
        closure(&copy)
        return copy
    }
}

public extension View {
    static var typeName: String { String(describing: self) }
}

public extension AnyView {
    static var name: String { String(describing: self) }
}
