import SwiftUI

@MainActor
@propertyWrapper
public struct LazyState<T: Observable>: @MainActor DynamicProperty {
	@State private var holder: Holder

	public var wrappedValue: T {
		holder.wrappedValue
	}

	public var projectedValue: Binding<T> {
		Binding(get: { wrappedValue }, set: { _ in })
	}

	public func update() {
		guard !holder.onAppear else { return }
		holder.setup()
	}

	public init(wrappedValue thunk: @autoclosure @escaping () -> T) {
		_holder = State(wrappedValue: Holder(wrappedValue: thunk()))
	}
}

extension LazyState {
	final class Holder {
		private var object: T!
		private let thunk: () -> T
		var onAppear = false
		var wrappedValue: T {
			object
		}

		func setup() {
			object = thunk()
			onAppear = true
		}

		init(wrappedValue thunk: @autoclosure @escaping () -> T) {
			self.thunk = thunk
		}
	}
}
