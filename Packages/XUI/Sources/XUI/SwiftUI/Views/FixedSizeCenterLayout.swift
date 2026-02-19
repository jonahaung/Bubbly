//
//  FixedSizeCenterLayout.swift
//  XUI
//
//  Created by Aung Ko Min on 19/2/26.
//


import SwiftUI

public struct FixedSizeCenterLayout: Layout {

	private let size: CGSize

	public init(_ size: CGSize) {
		self.size = size
	}

	public init(square: CGFloat) {
		self.size = CGSize(width: square, height: square)
	}

	public func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) -> CGSize {
		size
	}

	public func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout ()
	) {
		let proposal = ProposedViewSize(size)

		for subview in subviews {
			subview.place(
				at: CGPoint(x: bounds.midX, y: bounds.midY),
				anchor: .center,
				proposal: proposal
			)
		}
	}
}