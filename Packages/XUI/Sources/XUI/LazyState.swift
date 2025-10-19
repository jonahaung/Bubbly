//
//  LazyState.swift
//  XUI
//
//  Created by Aung Ko Min on 18/10/25.
//

import SwiftUI

@MainActor // Ensure the property wrapper operates on the main thread to complete setup before accessing wrappedValue
@propertyWrapper
public struct LazyState<T: Observable>: @preconcurrency DynamicProperty { // Restricted to use with Observable types
	@State private var holder: Holder

	// To maintain consistency with State and StateObject, the instance is created only once and is immutable (no setter provided)
	public var wrappedValue: T {
		holder.wrappedValue
	}

	public var projectedValue: Binding<T> {
		// Since modifications are only done via key paths, the setter is ignored.
		return Binding(get: { wrappedValue }, set: { _ in })
	}

	// Called when the view loads, to create the instance.
	public func update() {
		guard !holder.onAppear else { return }
		holder.setup()
	}

	public init(wrappedValue thunk: @autoclosure @escaping () -> T) {
		_holder = State(wrappedValue: Holder(wrappedValue: thunk()))
	}
}

extension LazyState {
	// Helper class to hold the instance.
	final class Holder {
		private var object: T!
		private let thunk: () -> T
		// Flag to mark whether the instance has been initialized, to avoid duplicate creations.
		var onAppear = false
		var wrappedValue: T {
			object
		}

		func setup() {
			object = thunk() // Lazily initialize the instance.
			onAppear = true  // Mark as initialized to prevent further calls.
		}

		init(wrappedValue thunk: @autoclosure @escaping () -> T) {
			self.thunk = thunk
		}
	}
}
