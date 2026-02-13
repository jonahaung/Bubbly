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
	/// Prevents the view from updating its child view when its new given value is the same as its
	/// old given value.
	func equatable(by value: some Equatable) -> some View {
		EqualableView(content: self, value: value)
			.equatable()
	}
}

public struct DoubleEqualableView<Content: View, Value: Equatable>: Sendable,
	@preconcurrency Equatable, View
{
	public let content: Content
	public let values: [Value]

	public var body: some View {
		content
	}

	@MainActor
	public static func == (lhs: DoubleEqualableView, rhs: DoubleEqualableView) -> Bool {
		lhs.values == rhs.values
	}
}

public extension View {
	/// Prevents the view from updating its child view when its new given value is the same as its
	/// old given value.
	func equatable(by values: [AnyEquatable]) -> some View {
		DoubleEqualableView(content: self, values: values)
			.equatable()
	}

	func animation(_ animation: Animation, values: [String]) -> some View {
		self.animation(animation, value: values)
	}
}
