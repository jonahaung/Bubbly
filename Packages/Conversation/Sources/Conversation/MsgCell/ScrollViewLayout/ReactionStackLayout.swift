// © 2026 Aung Ko Min
import SwiftUI
public struct ReactionStackLayout: Layout {
    public init(overlap: CGFloat = 12) { self.overlap = overlap }
    // MARK: Public
    public var overlap: CGFloat
    public func sizeThatFits(
        proposal: ProposedViewSize, subviews: Subviews, cache _: inout (),
    ) -> CGSize {
        var width: CGFloat = 0
        var height: CGFloat = 0
        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(proposal)
            if index == 0 { width += size.width } else { width += size.width - overlap }
            height = max(height, size.height)
        }
        return CGSize(width: width, height: height)
    }
    public func placeSubviews(
        in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache _: inout (),
    ) {
        var x = bounds.maxX
        for subview in subviews {
            let size = subview.sizeThatFits(proposal)
            x -= size.width
            subview.place(
                at: CGPoint(x: x, y: bounds.midY - size.height / 2), anchor: .topLeading,
                proposal: ProposedViewSize(size), )
            x += overlap
        }
    }
}
