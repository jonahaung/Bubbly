//
//  DynamicOffsetLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 16/2/26.
//

import SwiftUI

struct DynamicOffsetLayout: Layout {

    let totalHeight: CGFloat
    let offsets: [Int: CGFloat]

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {
        CGSize(
            width: proposal.width ?? 0,
            height: totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {
        for subview in subviews {
            let index = subview[LayoutIndex.self]
            let y = offsets[index] ?? 0

            subview.place(
                at: CGPoint(
                    x: bounds.minX,
                    y: bounds.minY + y
                ),
                anchor: .topLeading,
                proposal: proposal
            )
        }
    }
}
