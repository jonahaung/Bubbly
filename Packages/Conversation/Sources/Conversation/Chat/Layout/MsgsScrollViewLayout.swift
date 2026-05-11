//  MsgsScrollViewLayout.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct MsgsScrollViewLayout: Layout {
    init(manager: MsgsScrollViewLayoutManager, config: MsgsScrollViewLayoutConfiguration) {
        self.manager = manager
        self.config = config
    }

    @preconcurrency private let manager: MsgsScrollViewLayoutManager
    private let config: MsgsScrollViewLayoutConfiguration
    private var cacheStore: MsgsScrollViewLayoutCache { manager.cache }
}

extension MsgsScrollViewLayout {
    func makeCache(subviews: Subviews) -> Cache { buildCache(subviews: subviews) }
    
    func sizeThatFits(
        proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache
    ) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        guard !subviews.isEmpty else { return config.screenSize }
        return .init(width: size.width, height: cache.totalHeight)
    }

    func placeSubviews(
        in rect: CGRect, proposal _: ProposedViewSize, subviews: Subviews, cache: inout Cache
    ) {
        for i in subviews.indices {
            let layout = cache.layouts[i]
            subviews[i].place(
                at: layout.position, anchor: layout.anchor, proposal: ProposedViewSize(layout.size)
            )
        }
    }
    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        cache = buildCache(subviews: subviews)
    }
    
//    func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGFloat? {
//        guard !subviews.isEmpty else { return nil }
//        if cache.layouts.count != subviews.count { cache = buildCache(subviews: subviews) }
//        guard cache.layouts.count == subviews.count else { return nil }
//
//        switch guide {
//        case .leading:
//            let minX = cache.layouts.map { $0.position.x }.min()
//            return minX
//        case .trailing:
//            let maxX = cache.layouts.map { $0.position.x }.max()
//            return maxX
//        default:
//            return nil
//        }
//    }
//    func explicitAlignment(of guide: VerticalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGFloat? {
//        guard !subviews.isEmpty else { return nil }
//        if cache.layouts.count != subviews.count { cache = buildCache(subviews: subviews) }
//        guard cache.layouts.count == subviews.count else { return nil }
//
//        switch guide {
//        case .top:
//            let minY = cache.layouts.map { $0.position.y }.min()
//            return minY
//        case .bottom:
//            let maxY = cache.layouts.map { $0.position.y }.max()
//            return maxY
//        default:
//            return nil
//        }
//    }
}

// MARK: - Cache Builder
extension MsgsScrollViewLayout {
    private func buildCache(subviews: Subviews) -> Cache {
        let signature = makeSignature(subviews: subviews)
        if let cached = cacheStore.cache(signature: signature) { return cached }
        let (layouts, totalHeight) = computeLayouts(subviews: subviews)
        let cache = Cache(totalHeight: totalHeight, layouts: layouts, signatureHash: signature )
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
            layouts.append(.init(id: value.uid, size: size, position: .init(x: x, y: y), anchor: value.anchor) )
            y += size.height + config.spacing
        }
        return (layouts, totalHeight(for: layouts))
    }
}

private extension MsgsScrollViewLayout {
    func size(for subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {
        let key = sizeKey(for: value)
        if let cached = cacheStore.size(for: key) { return cached }
        let size = measure(subview: subview, value: value)
        cacheStore.setSize(size, for: key)
        return size
    }

    func measure(subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {
        let ratio: CGFloat =
            switch value.attachmentsCount {
            case 0: 1
            case 1: 0.7
            default: 0.7
            }
        let availableTotalWidth = (config.boundsWidth - config.contentInsets.horizontal) * ratio
        let targetedMaxWidth = availableTotalWidth * config.bubbleWidthRatio
        let measured = subview.sizeThatFits(ProposedViewSize(width: targetedMaxWidth, height: nil))
        return measured
    }

    func sizeKey(for value: MsgLayoutValue) -> MsgsScrollViewLayout.SizeKey {
        let selected = value.uid == manager.selectedMsg?.id
        return .init(uid: value.uid, width: config.boundsWidth.int, selected: selected, headerID: value.headerID)
    }

    func xPosition(for recipient: MsgRecipient) -> CGFloat {
        switch recipient {
        case .incoming: config.contentInsets.leading
        case .outgoing: config.boundsWidth - config.contentInsets.trailing
        case .system: (config.boundsWidth) * 0.5
        }
    }

    func totalHeight(for layouts: [Cache.CellLayout]) -> CGFloat {
        guard !layouts.isEmpty else { return config.screenSize.height }
        let totalContentHeight = layouts.reduce(into: 0.0) { $0 += $1.size.height }
        let totalSpacing = config.spacing * CGFloat(max(0, layouts.count - 1))
        return config.contentInsets.vertical + totalContentHeight + totalSpacing
    }
}

extension MsgsScrollViewLayout {
    private func makeSignature(subviews: Subviews) -> Int {
        var hasher = Hasher()
        hasher.combine(Int(config.boundsWidth))
        if let selected = manager.selectedMsg { hasher.combine(selected.id) }
        for subview in subviews {
            let value = subview[MsgLayoutValueKey.self]
            hasher.combine(value.id)
            hasher.combine(value.headerID)
        }
        return hasher.finalize()
    }
}
