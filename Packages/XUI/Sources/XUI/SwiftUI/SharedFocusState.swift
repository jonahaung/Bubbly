//  SharedFocusState.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftUI

@MainActor
@Observable
public final class SharedFocusState {
    public let binding: FocusState<String?>.Binding

    public init(_ binding: FocusState<String?>.Binding) {
        self.binding = binding
    }

    public var value: String? {
        get { binding.wrappedValue }
        set { binding.wrappedValue = newValue }
    }

    public func focus(_ value: String?) {
        self.value = value
    }

    public func isFocused(for value: String) -> Bool {
        self.value == value
    }

    public func defocus() {
        guard value != nil else { return }
        withTransaction(.withAnimation(.interactiveSpring)) {
            self.value = nil
        }
    }
}

public extension EnvironmentValues {
    @Entry var sharedFocusState: SharedFocusState?
}
