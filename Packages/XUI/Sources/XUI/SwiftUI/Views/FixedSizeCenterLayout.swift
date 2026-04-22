//  FixedSizeCenterLayout.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

public struct FixedSizeCenterLayout: Layout {

    private let size: CGSize

    public init(_ size: CGSize) {
        self.size = size
    }

    public init(square: CGFloat) {
        size = CGSize(width: square, height: square)
    }

    public func sizeThatFits(
        proposal _: ProposedViewSize,
        subviews _: Subviews,
        cache _: inout ()
    ) -> CGSize {
        size
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache _: inout ()
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
