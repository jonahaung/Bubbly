import SwiftUI

private struct ChangePredicatedAnimation<Value: Equatable>: ViewModifier {
	let animation: Animation?
	let value: Value
	let predicate: ((oldValue: Value, newValue: Value)) -> Bool

	@State var lastValue: Value?

	init(animation: Animation?,
	     value: Value,
	     initialValue: Value?,
	     predicate: @escaping ((oldValue: Value, newValue: Value)) -> Bool)
	{
		self.animation = animation
		self.value = value
		self.predicate = predicate

		_lastValue = .init(wrappedValue: initialValue)
	}

	func body(content: Content) -> some View {
		content
			.transaction { view in
				if let lastValue {
					if predicate((lastValue, value)) {
						view.animation = animation
					}
				}
			}
			.onChange(of: value) { _, newValue in
				lastValue = newValue
			}
	}
}

public extension View {
	func predicatedAnimation<Value: Equatable>(_ animation: Animation?,
	                                           value: Value,
	                                           initialValue: Value? = nil,
	                                           predicate: @escaping ((
	                                           	oldValue: Value,
	                                           	newValue: Value
	                                           )) -> Bool) -> some View
	{
		modifier(ChangePredicatedAnimation(
			animation: animation,
			value: value,
			initialValue: initialValue,
			predicate: predicate
		))
	}
}
