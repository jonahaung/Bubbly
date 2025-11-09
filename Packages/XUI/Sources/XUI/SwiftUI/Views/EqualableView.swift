//
//  EqualableView.swift
//
//
//  Created by Aung Ko Min on 17/7/23.
//

import SwiftUI

public struct EqualableView<Content: View, Value: Equatable>: @preconcurrency Equatable, View {
    public let content: Content
    public let value: Value

    public var body: some View {
        content
    }

    public static func == (lhs: EqualableView, rhs: EqualableView) -> Bool {
        lhs.value == rhs.value
    }

    public init(content: Content, value: Value) {
        self.content = content
        self.value = value
    }
}

public extension View {
    /// Prevents the view from updating its child view when its new given value is the same as its old given value.
    func equatable(by value: some Equatable) -> some View {
        EqualableView(content: self, value: value)
            .equatable()
    }
}

public struct DoubleEqualableView<Content: View, Value: Equatable, Value2: Equatable>: Sendable, @preconcurrency Equatable, View {
    public let content: Content
    public let value: Value
    public let value2: Value2

    public var body: some View {
        content
    }

    @MainActor
    public static func == (lhs: DoubleEqualableView, rhs: DoubleEqualableView) -> Bool {
        lhs.value == rhs.value && lhs.value2 == rhs.value2
    }

    public init(content: Content, value: Value, value2: Value2) {
        self.content = content
        self.value = value
        self.value2 = value2
    }
}

public extension View {
    /// Prevents the view from updating its child view when its new given value is the same as its old given value.
    func equatable<value2: Equatable>(by value: some Equatable, value2: value2) -> some View {
        DoubleEqualableView(content: self, value: value, value2: value2)
            .equatable()
    }
}
