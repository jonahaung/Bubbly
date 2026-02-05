//
//  BubbleTextLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/2/26.
//

import SwiftUI

struct BubbleTextLayout: Layout {

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {
		subviews.first?.sizeThatFits(proposal) ?? .zero
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {
		subviews.first?.place(
			at: bounds.origin,
			proposal: proposal
		)
	}
}
