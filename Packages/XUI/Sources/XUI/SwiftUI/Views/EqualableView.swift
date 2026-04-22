//  EqualableView.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

public struct EquatableView<Content: View, Value: Equatable & SendableMetatype>: View,
    @MainActor Equatable
{

    private let content: () -> Content
    public let value: Value

    public init(
        value: Value,
        @ViewBuilder content: @escaping () -> Content
    ) {
        self.value = value
        self.content = content
    }

    public var body: some View {
        content()
    }

    public static func == (
        lhs: EquatableView<Content, Value>,
        rhs: EquatableView<Content, Value>
    ) -> Bool {
        lhs.value == rhs.value
    }
}

// MARK: - View Extension

public extension View {
    func equatable(
        by value: some Equatable & SendableMetatype
    ) -> some View {
        EquatableView(value: value) {
            self
        }
    }
}
