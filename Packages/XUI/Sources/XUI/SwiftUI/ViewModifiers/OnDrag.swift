import SwiftUI

public enum DragDirection: Hashable {
	case left, right, scrollUp, down

	@available(iOS 13.0, *)
	func isValid(value: DragGesture.Value, distance: CGFloat) -> Bool {
		switch self {
		case .left:
			value.startLocation.x - value.location.x > distance
		case .right:
			value.location.x - value.startLocation.x > distance
		case .scrollUp:
			value.startLocation.y - value.location.y > distance
		case .down:
			value.location.y - value.startLocation.y > distance
		}
	}
}

private struct _OnDragModifier: ViewModifier {
	let direction: DragDirection
	let distance: CGFloat
	let perform: () -> Void
	@State private var offset = CGPoint.zero

	func body(content: Content) -> some View {
		content
			.transformEffect(.init(translationX: offset.x, y: offset.y))
			.gesture(
				DragGesture()
					.onChanged { value in
						if direction.isValid(value: value, distance: 10) {
							switch direction {
							case .left:
								offset.x = value.startLocation.x - value.location.x
							case .right:
								offset.x = value.startLocation.x - value.location.x
							case .scrollUp:
								offset.y = value.location.y - value.startLocation.y
							case .down:
								offset.y = value.location.y - value.startLocation.y
							}
						}
					}
					.onEnded(handleDrag(_:))
			)
	}

	private func handleDrag(_ value: DragGesture.Value) {
		offset = .zero
		if direction.isValid(value: value, distance: distance) {
			Haptics.play(.soft, 0.8)
			DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
				perform()
			}
		}
	}
}

public extension View {
	func onDrag(_ direction: DragDirection,
	            _ distance: CGFloat = 100,
	            _ perform: @escaping () -> Void) -> some View
	{
		modifier(_OnDragModifier(direction: direction, distance: distance, perform: perform))
	}
}
