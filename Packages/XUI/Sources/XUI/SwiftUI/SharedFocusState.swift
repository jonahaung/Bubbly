//
//  SharedFocusState.swift
//  XUI
//
//  Created by Aung Ko Min on 31/8/25.
//


import SwiftUI

@Observable
public final class SharedFocusState {
	public var value: FocusState<Bool>.Binding?
	public init(_ focusState: FocusState<Bool>.Binding) {
		self.value = focusState
	}
}
struct SharedFocusStateEnvironmentKey: @preconcurrency EnvironmentKey {
	@MainActor
	static let defaultValue: SharedFocusState? = nil
}
extension EnvironmentValues {
	public var focusState: SharedFocusState? {
		get { self[SharedFocusStateEnvironmentKey.self] }
		set { self[SharedFocusStateEnvironmentKey.self] = newValue }
	}
}
public extension View {
	func focusState(_ value: FocusState<Bool>.Binding) -> some View {
		environment(\.focusState, SharedFocusState(value))
	}
}
