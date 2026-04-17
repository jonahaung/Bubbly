// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI



struct MsgsScrollViewLayoutConfiguration {

    init(
        spacing: CGFloat,
        contentInsets: EdgeInsets,
        boundsWidth: CGFloat,
        selectedMsg: SelectedMsg? = nil
    ) {
        self.spacing = spacing
        self.contentInsets = contentInsets
        self.boundsWidth = boundsWidth
        self.selectedMsg = selectedMsg
    }

    enum Constants {
        static let bubbleWidthRatio: CGFloat = 0.9
        static let maxBubbleHeight: CGFloat = 600
    }

    let spacing: CGFloat
    let contentInsets: EdgeInsets
    let boundsWidth: CGFloat
    let selectedMsg: SelectedMsg?
}

// MARK: - Layout

struct MsgsScrollViewLayout: Layout, @unchecked Sendable {

    init(
        manager: MsgsScrollViewLayoutManager,
        config: MsgsScrollViewLayoutConfiguration
    ) {
        self.manager = manager
        self.config = config
    }

    @preconcurrency private let manager: MsgsScrollViewLayoutManager
    private let config: MsgsScrollViewLayoutConfiguration

    private var cacheStore: MsgsScrollViewLayoutCache { manager.cache }
}

// MARK: - Layout Core

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
        cache: inout Cache
    ) -> CGSize {
        let size = proposal.replacingUnspecifiedDimensions()
        guard !subviews.isEmpty else { return size }

        return .init(
            width: size.width,
            height: max(size.height, cache.totalHeight)
        )
    }

    func placeSubviews(
        in _: CGRect,
        proposal _: ProposedViewSize,
        subviews: Subviews,
        cache: inout Cache
    ) {
        guard cache.layouts.count == subviews.count else { return }

        for (i, subview) in subviews.enumerated() {
            let layout = cache.layouts[i]
            let value = subview[MsgLayoutValueKey.self]

            subview.place(
                at: layout.position,
                anchor: value.anchor,
                proposal: ProposedViewSize(layout.size)
            )
        }
    }

    func explicitAlignment(
        of guide: HorizontalAlignment,
        in _: CGRect,
        proposal _: ProposedViewSize,
        subviews _: Subviews,
        cache: inout Cache
    ) -> CGFloat? {
        guard !cache.layouts.isEmpty else { return nil }

        switch guide {
        case .leading: return config.contentInsets.leading
        case .trailing:
            return config.boundsWidth - config.contentInsets.trailing
        case .center: return config.boundsWidth * 0.5
        default: return nil
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
            signatureHash: signature
        )

        cacheStore.setCache(cache, signature: signature)
        return cache
    }
}

// MARK: - Layout Computation

extension MsgsScrollViewLayout {

    private func computeLayouts(
        subviews: Subviews
    ) -> ([Cache.CellLayout], CGFloat) {

        var layouts: [Cache.CellLayout] = []
        layouts.reserveCapacity(subviews.count)

        var y = config.contentInsets.top

        for subview in subviews {
            let value = subview[MsgLayoutValueKey.self]

            let size = size(for: subview, value: value)
            let x = xPosition(for: value.recipient)

            layouts.append(
                .init(id: value.uid, size: size, position: .init(x: x, y: y))
            )
            y += size.height + config.spacing
        }

        return (layouts, totalHeight(for: layouts))
    }
}

// MARK: - Size

extension MsgsScrollViewLayout {

    private func size(
        for subview: LayoutSubview,
        value: MsgLayoutValue
    ) -> CGSize {

        let key = sizeKey(for: value)

        if let cached = cacheStore.size(for: key) {
            return cached
        }

        let size = measure(subview: subview, value: value)
        cacheStore.setSize(size, for: key)

        return size
    }

    private func measure(
        subview: LayoutSubview,
        value: MsgLayoutValue
    ) -> CGSize {

        let ratio: CGFloat = {
            switch value.attachmentsCount {
            case 0: return 1
            case 1: return 0.7
            default: return 0.8
            }
        }()

        let containerWidth =
            (config.boundsWidth - config.contentInsets.horizontal) * ratio
        let width =
            containerWidth
            * MsgsScrollViewLayoutConfiguration.Constants.bubbleWidthRatio

        let proposed = ProposedViewSize(width: width, height: .infinity)
        let measured = subview.sizeThatFits(proposed)

        return .init(
            width: measured.width,
            height: measured.height
        )
    }

    private func sizeKey(for value: MsgLayoutValue) -> String {
        let width = Int(config.boundsWidth)
        let selected = value.uid == manager.selectedMsg?.id
        return "\(value.uid)|\(width)|\(selected)"
    }
}

// MARK: - Positioning

extension MsgsScrollViewLayout {

    private func xPosition(for recipient: MsgRecipient) -> CGFloat {
        switch recipient {
        case .incoming: return config.contentInsets.leading
        case .outgoing:
            return config.boundsWidth - config.contentInsets.trailing
        case .system:
            return (config.boundsWidth) * 0.5
        }
    }

    private func totalHeight(for layouts: [Cache.CellLayout]) -> CGFloat {
        guard !layouts.isEmpty else { return 0 }

        let content = layouts.reduce(0) { $0 + $1.size.height }
        let spacing = config.spacing * CGFloat(layouts.count - 1)

        return config.contentInsets.vertical + content + spacing
    }
}

// MARK: - Signature

extension MsgsScrollViewLayout {

    private func makeSignature(subviews: Subviews) -> Int {
        var hasher = Hasher()

        hasher.combine(Int(config.boundsWidth))
        hasher.combine(config.spacing)
        hasher.combine(config.contentInsets.top)
        hasher.combine(config.contentInsets.leading)

        if let selected = manager.selectedMsg {
            hasher.combine(selected.id)
        }

        for subview in subviews {
            hasher.combine(subview[MsgLayoutValueKey.self].hashValue)
        }

        return hasher.finalize()
    }
}

// MARK: - Cache

extension MsgsScrollViewLayout {

    struct Cache: Hashable {

        struct CellLayout: Hashable {
            let id: String
            let size: CGSize
            let position: CGPoint

            var frame: CGRect { .init(origin: position, size: size) }
        }

        let totalHeight: CGFloat
        let layouts: [CellLayout]
        let signatureHash: Int
    }
}
