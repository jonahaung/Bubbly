// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayout: Layout {

    init(manager: MsgsScrollViewLayoutManager, config: MsgsScrollViewLayoutConfiguration) {
        self.manager = manager
        self.config = config
    }

    @preconcurrency private let manager: MsgsScrollViewLayoutManager
    private let config: MsgsScrollViewLayoutConfiguration
    private var cacheStore: MsgsScrollViewLayoutCache {
        manager.cache
    }
}

extension MsgsScrollViewLayout {

    func makeCache(subviews: Subviews) -> Cache {
        buildCache(subviews: subviews)
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = buildCache(subviews: subviews)
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache,
    ) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        guard !subviews.isEmpty else {
            return size
        }

        return .init(
            width: size.width,
            height: max(size.height, cache.totalHeight),
        )
    }

    func placeSubviews(
        in rect: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache,
    ) {
        guard cache.layouts.count == subviews.count else {
            return
        }

        for (i, subview) in subviews.enumerated() {
            let layout = cache.layouts[i]
            let value = subview[MsgLayoutValueKey.self]
            let absolutePosition = CGPoint(
                x: rect.minX + layout.position.x,
                y: rect.minY + layout.position.y,
            )
            subview.place(
                at: absolutePosition,
                anchor: value.anchor,
                proposal: ProposedViewSize(layout.size),
            )
        }
    }
}

// MARK: - Cache Builder

extension MsgsScrollViewLayout {

    private func buildCache(subviews: Subviews) -> Cache {
        let signature = makeSignature(subviews: subviews)

        if let cached = cacheStore.cache(signature: signature) {
            return cached
        }

        let (layouts, totalHeight) = computeLayouts(subviews: subviews)

        let cache = Cache(
            totalHeight: totalHeight,
            layouts: layouts,
            signatureHash: signature,
        )

        cacheStore.setCache(cache, signature: signature)
        return cache
    }
}

// MARK: - Layout Computation

extension MsgsScrollViewLayout {

    private func computeLayouts(subviews: Subviews) -> ([Cache.CellLayout], CGFloat) {

        var layouts = [Cache.CellLayout]()
        layouts.reserveCapacity(subviews.count)

        var y = config.contentInsets.top

        for subview in subviews {
            let value = subview[MsgLayoutValueKey.self]

            let size = size(for: subview, value: value)
            let x = xPosition(for: value.recipient)

            layouts.append(
                .init(id: value.uid, size: size, position: .init(x: x, y: y)),
            )
            y += size.height + config.spacing
        }

        return (layouts, totalHeight(for: layouts))
    }
}

private extension MsgsScrollViewLayout {
    func size(for subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {
        let key = sizeKey(for: value)

        if let cached = cacheStore.size(for: key) {
            return cached
        }

        let size = measure(subview: subview, value: value)
        cacheStore.setSize(size, for: key)

        return size
    }

    func measure(subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {

        let ratio: CGFloat =
            switch value.attachmentsCount {
            case 0: 1
            case 1: 0.6
            default: 0.7
            }

        let availableTotalWidth = (config.boundsWidth - config.contentInsets.horizontal) * ratio
        let targetedMaxWidth = availableTotalWidth * config.bubbleWidthRatio
        let measured = subview.sizeThatFits(ProposedViewSize(width: targetedMaxWidth, height: nil))
        return .init(
            width: measured.width,
            height: measured.height,
        )
    }

    func sizeKey(for value: MsgLayoutValue) -> MsgsScrollViewLayout.SizeKey {
        let selected = value.uid == manager.selectedMsg?.id
        return .init(uid: value.uid, width: config.boundsWidth, selected: selected)
    }
    func xPosition(for recipient: MsgRecipient) -> CGFloat {
        switch recipient {
        case .incoming: config.contentInsets.leading
        case .outgoing:
            config.boundsWidth - config.contentInsets.trailing
        case .system:
            (config.boundsWidth) * 0.5
        }
    }

    func totalHeight(for layouts: [Cache.CellLayout]) -> CGFloat {
        guard !layouts.isEmpty else {
            return config.screenSize.height
        }
        let totalContentHeight = layouts.reduce(into: 0.0) { $0 += $1.size.height }
        let totalSpacing = config.spacing * CGFloat(max(0, layouts.count - 1))

        return config.contentInsets.vertical + totalContentHeight + totalSpacing
    }
}

extension MsgsScrollViewLayout {

    private func makeSignature(subviews: Subviews) -> Int {
        var hasher = Hasher()
        hasher.combine(Int(config.boundsWidth))
        if let selected = manager.selectedMsg {
            hasher.combine(selected.id)
        }
        for subview in subviews {
            hasher.combine(subview[MsgLayoutValueKey.self].id)
        }
        return hasher.finalize()
    }
}
