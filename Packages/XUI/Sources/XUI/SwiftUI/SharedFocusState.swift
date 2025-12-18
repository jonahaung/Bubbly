//
//  SharedFocusState.swift
//  XUI
//
//  Created by Aung Ko Min on 31/8/25.
//

import SwiftUI

@MainActor
@Observable
public final class SharedFocusState {
	public let binding: FocusState<Bool>.Binding

	public init(_ binding: FocusState<Bool>.Binding) {
		self.binding = binding
	}

	public var isFocused: Bool {
		get { binding.wrappedValue }
		set { binding.wrappedValue = newValue }
	}

	public func focus() { isFocused = true }
	public func defocus() { isFocused = false }
	public func toggle() { isFocused.toggle() }
}

private struct SharedFocusEnvironmentKey: EnvironmentKey {
	static let defaultValue: SharedFocusState? = nil
}

public extension EnvironmentValues {
	var sharedFocus: SharedFocusState? {
		get { self[SharedFocusEnvironmentKey.self] }
		set { self[SharedFocusEnvironmentKey.self] = newValue }
	}
}

public extension View {
	func sharedFocus(_ binding: FocusState<Bool>.Binding) -> some View {
		environment(\.sharedFocus, SharedFocusState(binding))
	}
}
