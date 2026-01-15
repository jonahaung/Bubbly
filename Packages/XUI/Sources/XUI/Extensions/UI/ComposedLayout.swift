import SwiftUI

public struct ComposedLayout: Layout {
    private let hStack = AnyLayout(HStackLayout(spacing: 1))
    private let vStack = AnyLayout(VStackLayout(spacing: 1))

    public struct Caches {
        var topCache: AnyLayout.Cache
        var centerCache: AnyLayout.Cache
        var bottomCache: AnyLayout.Cache
    }

    private let topColumns: Int
    private let bottomColumns: Int
    public init(topColumns: Int = 1, bottomColumns: Int = 2) {
        self.topColumns = topColumns
        self.bottomColumns = bottomColumns
    }

    public func makeCache(subviews: Subviews) -> Caches {
        Caches(topCache: hStack.makeCache(subviews: topViews(subviews: subviews)),
               centerCache: vStack.makeCache(subviews: centerViews(subviews: subviews)),
               bottomCache: hStack.makeCache(subviews: bottomViews(subviews: subviews)))
    }

    func topViews(subviews: LayoutSubviews) -> LayoutSubviews {
        subviews[..<min(subviews.count, topColumns)]
    }

    func centerViews(subviews: LayoutSubviews) -> LayoutSubviews {
        subviews.dropFirst(topColumns).dropLast(bottomColumns)
    }

    func bottomViews(subviews: LayoutSubviews) -> LayoutSubviews {
        if subviews.count < topColumns + 1 {
            subviews.dropLast(subviews.count) // return empty LayoutSubviews
        } else {
            subviews[max(subviews.count - bottomColumns, topColumns) ..< subviews.count]
        }
    }

    public func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Caches) -> CGSize {
        let tViews = topViews(subviews: subviews)
        let cViews = centerViews(subviews: subviews)
        let bViews = bottomViews(subviews: subviews)

        let tSize = tViews.count == 0 ? .zero : hStack.sizeThatFits(proposal: proposal, subviews: tViews, cache: &cache.topCache)
        let cSize = cViews.count == 0 ? .zero : vStack.sizeThatFits(proposal: proposal, subviews: cViews, cache: &cache.centerCache)
        let bSize = bViews.count == 0 ? .zero : hStack.sizeThatFits(proposal: proposal, subviews: bViews, cache: &cache.bottomCache)

        return CGSize(width: max(tSize.width, max(cSize.width, bSize.width)),
                      height: tSize.height + cSize.height + bSize.height)
    }

    public func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Caches) {
        let tViews = topViews(subviews: subviews)
        let cViews = centerViews(subviews: subviews)
        let bViews = bottomViews(subviews: subviews)

        var bounds = bounds

        if !tViews.isEmpty {
            let tSize = hStack.sizeThatFits(proposal: proposal, subviews: tViews, cache: &cache.topCache)
            hStack.placeSubviews(in: bounds, proposal: proposal, subviews: tViews, cache: &cache.topCache)

            bounds.origin = CGPoint(x: bounds.origin.x, y: bounds.origin.y + tSize.height)
        }

        if !cViews.isEmpty {
            let cSize = vStack.sizeThatFits(proposal: proposal, subviews: cViews, cache: &cache.centerCache)

            vStack.placeSubviews(in: bounds, proposal: proposal, subviews: cViews, cache: &cache.centerCache)

            bounds.origin = CGPoint(x: bounds.origin.x, y: bounds.origin.y + cSize.height)
        }

        if !bViews.isEmpty {
            hStack.placeSubviews(in: bounds, proposal: proposal, subviews: bViews, cache: &cache.bottomCache)
        }
    }
}
