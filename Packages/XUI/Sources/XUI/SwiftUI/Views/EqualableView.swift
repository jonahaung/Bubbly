//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI

public struct EquatableView<Content: View, Value: Equatable>: View, Equatable {

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

	nonisolated
	public static func == (
		lhs: EquatableView<Content, Value>,
		rhs: EquatableView<Content, Value>
	) -> Bool {
		lhs.value == rhs.value
	}
}

// MARK: - View Extension

public extension View {

	/// Prevents unnecessary view updates unless `value` changes.
	func equatable<Value: Equatable>(
		by value: Value
	) -> some View {
		EquatableView(value: value) {
			self
		}
	}
}
