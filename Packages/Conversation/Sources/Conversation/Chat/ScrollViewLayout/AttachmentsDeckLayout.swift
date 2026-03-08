import SwiftUI

public struct AttachmentsDeckLayout: Layout {

	public enum Alignment {
		case leading
		case trailing
	}

	public var alignment: Alignment
	public var xSpacing: CGFloat = 20
	public var ySpacing: CGFloat = 10

	public init(alignment: Alignment) {
		self.alignment = alignment
	}

	public func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {

		guard let first = subviews.first else { return .zero }

		let base = first.sizeThatFits(proposal)

		return CGSize(
			width: base.width + CGFloat(subviews.count) * xSpacing,
			height: base.height + CGFloat(subviews.count) * ySpacing
		)
	}

	public func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {

		for (index, subview) in subviews.enumerated() {

			let idx = CGFloat(index)

			let xOffset = (alignment == .trailing ? -xSpacing : xSpacing) * idx
			let yOffset = -(idx * ySpacing)

			subview.place(
				at: CGPoint(
					x: bounds.midX + xOffset,
					y: bounds.maxY + yOffset
				),
				anchor: alignment == .trailing ? .bottomLeading : .bottomTrailing,
				proposal: proposal
			)
		}
	}
}
