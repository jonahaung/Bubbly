//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayoutConfiguration {
    let superTopSpace = CGFloat(50)
    let spacing: CGFloat
    let contentInsets: EdgeInsets
    var boundsWidth: CGFloat

    init(_ spacing: CGFloat, _ contentInsets: EdgeInsets) {
        self.spacing = spacing
        self.contentInsets = contentInsets
        boundsWidth = 0
    }
}

struct MsgsScrollViewLayout: Layout {
    private let layoutManager: MsgsScrollViewLayoutManager
    private var config: MsgsScrollViewLayoutConfiguration {
        layoutManager.config
    }

    var animatableData: CGFloat {
        get { layoutManager.config.boundsWidth }
        set { layoutManager.updateBoundsWidth(newValue) }
    }

    init(_ manager: MsgsScrollViewLayoutManager) {
        layoutManager = manager
    }
}

extension MsgsScrollViewLayout {

    func makeCache(subviews: Subviews) -> Cache {
        calculateCache(for: subviews)
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        guard layoutManager.config.boundsWidth > 0 else {
            return .zero
        }
        let size = proposal.replacingUnspecifiedDimensions()
        return CGSize(
            width: size.width,
            height: cache.totalHeight
        )
    }

    func placeSubviews(
        in bounds: CGRect,
        proposal proposedViewSize: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard layoutManager.config.boundsWidth > 0 else {
            return
        }
        let proposedSize = proposedViewSize.replacingUnspecifiedDimensions()
        let x = bounds.minX + config.contentInsets.leading

        var currentY = cache.totalHeight - config.contentInsets.bottom
        let spacing = config.spacing

        for subview in subviews.reversed() {
            let value = subview[MsgLayoutValueKey.self]
            let size = getOrCalculateSize(
                for: value,
                subview: subview,
                proposedWidth: proposedSize.width
            )
            currentY -= size.height
            subview.place(at: .init(x: x, y: currentY), proposal: .init(size))
            currentY -= spacing
        }
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        guard layoutManager.config.boundsWidth > 0 else {
            return
        }
        let key = makeCacheKey(subviews: subviews)
        if cache.key != key {
            cache = calculateCache(
                for: subviews
            )
        }
    }
}

extension MsgsScrollViewLayout {

    private func calculateCache(
        for subviews: Subviews
    ) -> Cache {

        let signatureHash = makeCacheKey(
            subviews: subviews
        )

        if let cached = layoutManager.cache(for: signatureHash) {
            return cached
        }

        let totalHeight = calculateCellLayouts(
            for: subviews
        )

        let newCache = Cache(
            totalHeight: totalHeight, key: signatureHash
        )
        layoutManager.set(cache: newCache, for: signatureHash)
        return newCache
    }

    private func calculateCellLayouts(
        for subviews: Subviews
    ) -> CGFloat {

        var sizes = [CGSize]()
        let proposedWidth = layoutManager.boundsWidth
        for subview in subviews {
            let value = subview[MsgLayoutValueKey.self]

            let size = getOrCalculateSize(
                for: value,
                subview: subview, proposedWidth: proposedWidth
            )
            sizes.insert(size, at: 0)
        }
        return sizes.reduce(CGFloat.zero) { partialResult, size in
            partialResult + size.height + config.spacing
        } + config.contentInsets.vertical + config.superTopSpace
    }

    func spacing(subviews: Subviews, cache: inout Cache) -> ViewSpacing {
        .init()
    }

    func explicitAlignment(
        of guide: HorizontalAlignment,
        in bounds: CGRect,
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout ()
    ) -> CGFloat? {
        nil
    }
}

extension MsgsScrollViewLayout {

    private func getOrCalculateSize(
        for layoutValue: MsgLayoutValue,
        subview: LayoutSubview,
        proposedWidth: CGFloat
    ) -> CGSize {
        let key = SubviewKey(
            uid: layoutValue.id,
            isSelected: layoutValue.id == layoutManager.selectedMsg?.id,
            boundsWidth: proposedWidth
        )
        if let cachedSize = layoutManager.size(for: key) {
            return cachedSize
        }
        let calculatedSize = calculateOptimalSize(
            for: subview,
            layoutValue: layoutValue, proposedWidth: proposedWidth
        )

        layoutManager.set(size: calculatedSize, for: key)
        return calculatedSize
    }

    private func calculateOptimalSize(
        for subview: LayoutSubview,
        layoutValue: MsgLayoutValue,
        proposedWidth: CGFloat
    ) -> CGSize {
        let availableWidth = proposedWidth - config.contentInsets.horizontal
        let proposedViewSize = ProposedViewSize(
            width: availableWidth,
            height: nil
        )

        let dimension = subview.sizeThatFits(proposedViewSize)

        return CGSize(
            width: availableWidth,
            height: dimension.height
        )
    }
}

extension MsgsScrollViewLayout {

    private func makeCacheKey(
        subviews: LayoutSubviews
    ) -> CacheKey {
        .init(
            boundsWidth: layoutManager.boundsWidth,
            subviewKeys: subviews.map {
                let value = $0[MsgLayoutValueKey.self]
                return value.id
            },
            selectedMsgId: layoutManager.selectedMsg?.id
        )
    }
}

extension MsgsScrollViewLayout {
    struct SubviewKey: Hashable {
        let uid: String
        let isSelected: Bool
        let boundsWidth: CGFloat
    }

    struct CacheKey: Equatable, Hashable {

        let boundsWidth: CGFloat
        let subviewKeys: [String]
        let selectedMsgId: String?

        private var normalizedWidth: Int {
            Int(boundsWidth.rounded(.toNearestOrAwayFromZero))
        }

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.normalizedWidth == rhs.normalizedWidth &&
                lhs.subviewKeys == rhs.subviewKeys &&
                lhs.selectedMsgId == rhs.selectedMsgId
        }

        func hash(into hasher: inout Hasher) {
            hasher.combine(normalizedWidth)
            hasher.combine(subviewKeys)
            hasher.combine(selectedMsgId)
        }
    }

    struct Cache: Hashable {
        var totalHeight: CGFloat
        var key: CacheKey

        struct CellLayout: Hashable {
            let id: String
            let size: CGSize
            let y: CGFloat

            init(_ id: String, _ size: CGSize, _ y: CGFloat) {
                self.id = id
                self.size = size
                self.y = y
            }
        }
    }
}
