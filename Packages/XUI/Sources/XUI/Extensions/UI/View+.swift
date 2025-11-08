//
//  File.swift
//  
//
//  Created by Aung Ko Min on 10/6/23.
//

import SwiftUI

public extension View {

    @ViewBuilder func `if` <Content: View>(_ condition: Bool, _ transform: (Self) -> Content) -> some View {
        if condition {
            transform(self)
        } else {
            self
        }
    }

    @ViewBuilder func if_let <Content: View, T>(_ optional: T?, _ transform: (T, Self) -> Content) -> some View {
        if let optional {
            transform(optional, self)
        } else {
            self
        }
    }
	@inlinable
    func frame(size: CGSize?) -> some View {
		self.frame(width: size?.width, height: size?.height)
    }
	@inlinable
    func frame(square: CGFloat?) -> some View {
        self.frame(width: square, height: square)
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
