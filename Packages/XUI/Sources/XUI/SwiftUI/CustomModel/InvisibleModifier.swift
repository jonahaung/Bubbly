import SwiftUI

struct InvisibleModifier: @MainActor AnimatableModifier {
	public var percent: CGFloat
	public var animatableData: CGFloat {
		get { percent }
		set { percent = newValue }
	}

	public func body(content: Content) -> some View {
		content.opacity(percent == 1.0 ? 1 : 0)
	}
}
