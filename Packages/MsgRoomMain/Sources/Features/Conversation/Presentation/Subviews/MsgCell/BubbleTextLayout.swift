import SwiftUI

struct BubbleTextLayout: Layout {
	func sizeThatFits(proposal: ProposedViewSize,
	                  subviews: Subviews,
	                  cache _: inout ()) -> CGSize
	{
		subviews.first?.sizeThatFits(proposal) ?? .zero
	}

	func placeSubviews(in bounds: CGRect,
	                   proposal: ProposedViewSize,
	                   subviews: Subviews,
	                   cache _: inout ())
	{
		subviews.first?.place(
			at: bounds.origin,
			proposal: proposal
		)
	}
}
