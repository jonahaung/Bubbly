//  SharedFocusState.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

@MainActor
@Observable
public final class SharedFocusState<T: Hashable> {
    public let binding: FocusState<T?>.Binding

    public init(_ binding: FocusState<T?>.Binding) {
        self.binding = binding
    }

    public var value: T? {
        get { binding.wrappedValue }
        set { binding.wrappedValue = newValue }
    }

    public func focus(_ value: T?) {
        self.value = value
    }

    public func isFocused(for value: T) -> Bool {
        self.value == value
    }
    public func defocus() {
        guard value != nil else { return }
        withTransaction(.withAnimation(.interactiveSpring)) {
            self.value = nil
        }
    }
}
