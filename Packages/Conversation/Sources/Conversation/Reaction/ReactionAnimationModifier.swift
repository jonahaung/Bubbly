import Database
import SwiftUI

struct ReactionAnimationModifier: ViewModifier {
	let reaction: ReactionType
	let isActive: Bool

	func body(content: Content) -> some View {
		switch reaction {
		case .heart:
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset / 2 : 0)
				.scaleEffect(
					isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0,
					anchor: .bottom
				)

		case .thumbUp:
			content
				.rotationEffect(
					.degrees(isActive ? -ReactionsBar.Constants.rotationAngle : 0),
					anchor: .bottomLeading
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case .thumbDown:
			content
				.rotationEffect(
					.degrees(isActive ? -ReactionsBar.Constants.rotationAngle : 0),
					anchor: .leading
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case .laugh:
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset : 0)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		case .sad:
			content
				.offset(y: isActive ? ReactionsBar.Constants.floatOffset : 0)
				.rotationEffect(
					.degrees(isActive ? ReactionsBar.Constants.rotationAngle : 0)
				)
				.scaleEffect(isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0)

		default:
			content
				.scaleEffect(
					isActive ? ReactionsBar.Constants.scaleMultiplier : 1.0,
					anchor: .bottom
				)
		}
	}
}
