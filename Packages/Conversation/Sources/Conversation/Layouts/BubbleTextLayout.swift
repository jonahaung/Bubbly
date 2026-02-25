import SwiftUI

public struct SingleSubviewLayout: Layout {
	public func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache _: inout ()
	) -> CGSize {
		subviews.first?.sizeThatFits(proposal) ?? .zero
	}

	public func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache _: inout ()
	) {
		subviews.first?.place(
			at: bounds.origin,
			proposal: proposal
		)
	}
}
