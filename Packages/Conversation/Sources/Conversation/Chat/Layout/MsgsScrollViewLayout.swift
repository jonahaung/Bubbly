//  MsgsScrollViewLayout.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayout: Layout {
    static var layoutProperties: LayoutProperties {
        var properties = LayoutProperties()
        properties.stackOrientation = .vertical
        return properties
    }

    private let manager: MsgsScrollViewLayoutManager
    private let config: MsgsScrollViewLayoutConfiguration

    init(manager: MsgsScrollViewLayoutManager, config: MsgsScrollViewLayoutConfiguration) {
        self.manager = manager
        self.config = config
    }
}

extension MsgsScrollViewLayout {
    func makeCache(subviews: Subviews) -> Cache {
        buildCache(subviews: subviews, signature: makeSignature(subviews: subviews))
    }

    func sizeThatFits(
        proposal: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        guard !subviews.isEmpty else {
            return .init(width: size.width, height: config.screenSize.height)
        }
        return .init(width: config.boundsWidth, height: cache.totalHeight)
    }

    func placeSubviews(
        in rect: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        var y = rect.maxY - config.contentInsets.bottom
        let minX = rect.minX
        let spacing = config.spacing

        for subview in subviews.reversed() {
            let value = subview[MsgLayoutValueKey.self]
            let size = size(for: subview, value: value)
            y -= size.height
            subview.place(
                at: .init(x: xPosition(for: value.recipient) + minX, y: y),
                anchor: value.anchor,
                proposal: ProposedViewSize(size)
            )
            y -= spacing
        }
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        let signature = makeSignature(subviews: subviews)
        guard cache.signatureHash != signature else {
            return
        }
        cache = buildCache(subviews: subviews, signature: signature)
    }

    func spacing(subviews _: Subviews, cache _: inout Cache) -> ViewSpacing {
        .init()
    }
}

extension MsgsScrollViewLayout {
    private func buildCache(subviews: Subviews, signature: Int) -> Cache {
        if let cache = manager.cache(for: signature) {
            return cache
        }

        let cache = Cache(
            totalHeight: computeTotalHeight(subviews: subviews),
            signatureHash: signature
        )
        manager.setCache(cache)
        return cache
    }

    private func computeTotalHeight(subviews: Subviews) -> CGFloat {
        guard !subviews.isEmpty else {
            return config.screenSize.height
        }

        var totalHeight = config.contentInsets.vertical
        let lastIndex = subviews.count - 1

        for index in subviews.indices {
            let subview = subviews[index]
            let value = subview[MsgLayoutValueKey.self]
            totalHeight += size(for: subview, value: value).height
            if index != lastIndex {
                totalHeight += config.spacing
            }
        }

        return totalHeight
    }
}

private extension MsgsScrollViewLayout {
    func size(for subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {
        if let cached = manager.size(for: value, boundsWidth: config.boundsWidth.int) {
            return cached
        }
        let size = measure(subview: subview, value: value)
        manager.setSize(size, for: value, boundsWidth: config.boundsWidth.int)
        return size
    }

    func measure(subview: LayoutSubview, value: MsgLayoutValue) -> CGSize {
        let availableTotalWidth = config.boundsWidth - config.contentInsets.horizontal
        let maxWidthRatio: CGFloat = value.hasAttachment ? 0.7 : config.bubbleWidthRatio
        let targetedMaxWidth = availableTotalWidth * maxWidthRatio
        return subview.sizeThatFits(ProposedViewSize(width: targetedMaxWidth, height: .infinity))
    }

    func xPosition(for recipient: MsgRecipient) -> CGFloat {
        switch recipient {
        case .incoming:
            config.contentInsets.leading
        case .outgoing:
            config.boundsWidth - config.contentInsets.trailing
        case .system:
            config.boundsWidth * 0.5
        }
    }
}

extension MsgsScrollViewLayout {
    private func makeSignature(subviews: Subviews) -> Int {
        var hasher = Hasher()
        hasher.combine(subviews.count)
        for subview in subviews {
            let value = subview[MsgLayoutValueKey.self]
            hasher.combine(value)
        }
        return hasher.finalize()
    }
}
