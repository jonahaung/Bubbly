//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Reactions: View {
        let reactions: [Reaction]
        var body: some View {
            ReactionStackLayout {
                ForEach(
                    Array(reactions.reversed().enumerated()),
                    id: \.element
                ) { (index, reaction) in
                    Text(reaction.rawValue)
                        .font(.footnote)
                        .offset(x: index.cgFloat * -12)
                 }
            }
            .offset(y: -10)
            .padding(.horizontal, 8)
        }
    }
}

import SwiftUI

public struct ReactionStackLayout: Layout {

    public var overlap: CGFloat

    public init(overlap: CGFloat = 12) {
        self.overlap = overlap
    }

    public func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGSize {

        var width: CGFloat = 0
        var height: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(proposal)

            if index == 0 {
                width += size.width
            } else {
                width += size.width - overlap
            }

            height = max(height, size.height)
        }

        return CGSize(width: width, height: height)
    }

    public func placeSubviews(
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) {

        var x = bounds.maxX

        for subview in subviews {

            let size = subview.sizeThatFits(proposal)

            x -= size.width

            subview.place(
                at: CGPoint(x: x, y: bounds.midY - size.height / 2),
                anchor: .topLeading,
                proposal: ProposedViewSize(size)
            )

            x += overlap
        }
    }
}
