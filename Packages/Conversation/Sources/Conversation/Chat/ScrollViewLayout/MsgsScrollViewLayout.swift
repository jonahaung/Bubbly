//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayout: Layout {

    private let layoutManager: MsgsScrollViewLayoutManager
    private var config: MsgsScrollViewLayoutConfiguration {
        layoutManager.config
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
        let key = makeCacheKey(subviews: subviews)
        if cache.key == key {
            switch config.layoutDirection {
            case .top:
                for (subview, row) in zip(subviews, cache.rows) {
                    subview.place(at: row.rect.origin, proposal: .init(row.rect.size))
                }
            case .bottom:
                let rows = cache.rows.reversed()
                for (subview, row) in zip(subviews, rows) {
                    subview.place(at: row.rect.origin, proposal: .init(row.rect.size))
                }
            }
        } else {
            let proposedSize = proposedViewSize.replacingUnspecifiedDimensions()
            let x = bounds.minX + config.contentInsets.leading
            let values = subviews.map { $0[MsgLayoutValueKey.self] }

            let spacing = config.spacing
            switch config.layoutDirection {
            case .top:
                var currentY = config.contentInsets.top + config.superTopSpace
                let spacing = config.spacing

                for (index, subview) in subviews.enumerated() {
                    let value = values[index]
                    let size = getOrCalculateSize(
                        for: value,
                        subview: subview,
                        proposedWidth: proposedSize.width
                    )
                    subview.place(at: .init(x: x, y: currentY), proposal: .init(size))
                    currentY += size.height + spacing
                }
            case .bottom:
                var currentY = cache.totalHeight - config.contentInsets.bottom
                for (index, subview) in subviews.reversed().enumerated() {
                    let value = values[values.count - 1 - index]
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
        }
    }

    func updateCache(_ cache: inout Cache, subviews: Subviews) {
        guard layoutManager.config.boundsWidth > 0 else {
            return
        }
        let key = makeCacheKey(subviews: subviews)
        if cache.key == key {
            return
        }
        let oldIDs = ids(fromRows: cache.rows, direction: config.layoutDirection)
        let newIDs = subviews.map { $0[MsgLayoutValueKey.self].id }

        if shouldUseIncrementalUpdate(
            oldIDs: oldIDs,
            newIDs: newIDs,
            oldKey: cache.key,
            newKey: key
        ) {
            cache = buildIncrementalCache(
                from: cache,
                subviews: subviews,
                newIDs: newIDs,
                key: key
            )
            layoutManager.set(cache: cache, for: key)
            return
        }
        cache = calculateCache(for: subviews)
    }
}

extension MsgsScrollViewLayout {

    private func shouldUseIncrementalUpdate(
        oldIDs: [String],
        newIDs: [String],
        oldKey: CacheKey,
        newKey: CacheKey
    ) -> Bool {
        if oldKey.selectedMsgId != newKey.selectedMsgId {
            return false
        }
        if oldKey.normalizedWidth != newKey.normalizedWidth {
            return false
        }
        if oldIDs == newIDs {
            return true
        }
        let oldSet = Set(oldIDs)
        let newSet = Set(newIDs)
        let oldKept = oldIDs.filter { newSet.contains($0) }
        let newKept = newIDs.filter { oldSet.contains($0) }
        if oldKept != newKept {
            return false
        }
        let inserted = newIDs.filter { !oldSet.contains($0) }
        if !inserted.isEmpty {
            let topCount = newIDs.prefix(while: { !oldSet.contains($0) }).count
            let bottomCount = newIDs.reversed().prefix(while: { !oldSet.contains($0) }).count
            if topCount + bottomCount != inserted.count {
                return false
            }
        }
        let removed = oldIDs.filter { !newSet.contains($0) }
        if !removed.isEmpty {
            let topCount = oldIDs.prefix(while: { !newSet.contains($0) }).count
            let bottomCount = oldIDs.reversed().prefix(while: { !newSet.contains($0) }).count
            if topCount + bottomCount != removed.count {
                return false
            }
        }
        return true
    }

    private func ids(fromRows rows: [Cache.Row], direction: VerticalEdge) -> [String] {
        switch direction {
        case .top:
            return rows.map(\.id)
        case .bottom:
            return rows.reversed().map(\.id)
        }
    }

    private func buildIncrementalCache(
        from oldCache: Cache,
        subviews: Subviews,
        newIDs: [String],
        key: CacheKey
    ) -> Cache {
        let rowsByID = Dictionary(uniqueKeysWithValues: oldCache.rows.map { ($0.id, $0) })
        let subviewsByID = Dictionary(
            uniqueKeysWithValues: subviews.map { subview in
                let value = subview[MsgLayoutValueKey.self]
                return (value.id, subview)
            }
        )
        let proposedWidth = layoutManager.boundsWidth
        var rowsInOrder = [Cache.Row]()
        rowsInOrder.reserveCapacity(newIDs.count)
        for id in newIDs {
            if let existing = rowsByID[id] {
                rowsInOrder.append(
                    Cache.Row(id, rect: .init(origin: .zero, size: existing.rect.size))
                )
            } else if let subview = subviewsByID[id] {
                let value = subview[MsgLayoutValueKey.self]
                let size = getOrCalculateSize(
                    for: value,
                    subview: subview,
                    proposedWidth: proposedWidth
                )
                rowsInOrder.append(Cache.Row(id, rect: .init(origin: .zero, size: size)))
            }
        }
        let totalHeight =
            rowsInOrder.reduce(CGFloat.zero) { partialResult, row in
                partialResult + row.rect.height + config.spacing
            } + config.contentInsets.vertical + config.superTopSpace
        let x = config.contentInsets.leading
        var placedRows = rowsInOrder
        switch config.layoutDirection {
        case .top:
            var currentY = config.contentInsets.top + config.superTopSpace
            for index in placedRows.indices {
                let size = placedRows[index].rect.size
                placedRows[index] = Cache.Row(
                    placedRows[index].id,
                    rect: .init(origin: .init(x: x, y: currentY), size: size)
                )
                currentY += size.height + config.spacing
            }
            return Cache(
                key: key,
                totalHeight: totalHeight,
                rows: placedRows
            )
        case .bottom:
            var currentY = totalHeight - config.contentInsets.bottom
            for index in placedRows.indices.reversed() {
                let size = placedRows[index].rect.size
                currentY -= size.height
                placedRows[index] = Cache.Row(
                    placedRows[index].id,
                    rect: .init(origin: .init(x: x, y: currentY), size: size)
                )
                currentY -= config.spacing
            }
            return Cache(
                key: key,
                totalHeight: totalHeight,
                rows: placedRows.reversed()
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

        let (totalHeight, rows) = calculateCellLayouts(
            for: subviews
        )

        let newCache = Cache(
            key: signatureHash,
            totalHeight: totalHeight,
            rows: rows
        )
        layoutManager.set(cache: newCache, for: signatureHash)
        return newCache
    }

    private func calculateCellLayouts(
        for subviews: Subviews
    ) -> (totalHeight: CGFloat, rows: [Cache.Row]) {

        let values = subviews.map { $0[MsgLayoutValueKey.self] }
        var sizes = [CGSize]()
        let proposedWidth = layoutManager.boundsWidth

        for (index, subview) in subviews.enumerated() {
            let value = values[index]
            let size = getOrCalculateSize(
                for: value,
                subview: subview,
                proposedWidth: proposedWidth
            )
            sizes.append(size)
        }
        let totalHeight =
            sizes.reduce(CGFloat.zero) { partialResult, size in
                partialResult + size.height + config.spacing
            } + config.contentInsets.vertical + config.superTopSpace

        var rows = [Cache.Row]()
        let x = config.contentInsets.leading
        let spacing = config.spacing

        switch config.layoutDirection {
        case .top:
            var currentY = config.contentInsets.top + config.superTopSpace
            let spacing = config.spacing

            for (index, subview) in subviews.enumerated() {
                let value = values[index]
                let size = sizes[index]
                let origin = CGPoint(x: x, y: currentY)
                let row = Cache.Row(value.id, rect: .init(origin: origin, size: size))
                rows.append(row)
                currentY += size.height + spacing
            }
        case .bottom:
            sizes = sizes.reversed()
            var currentY = totalHeight - config.contentInsets.bottom
            for (index, subview) in subviews.reversed().enumerated() {
                let value = values[values.count - 1 - index]
                let size = sizes[index]
                currentY -= size.height
                let origin = CGPoint(x: x, y: currentY)
                let row = Cache.Row(value.id, rect: .init(origin: origin, size: size))
                rows.append(row)
                currentY -= spacing
            }
        }
        return (totalHeight, rows)
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
            layoutValue: layoutValue,
            proposedWidth: proposedWidth
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
        var idsHasher = Hasher()
        var idsCount = 0
        var firstID: String?
        var lastID: String?
        for subview in subviews {
            let id = subview[MsgLayoutValueKey.self].id
            if firstID == nil {
                firstID = id
            }
            lastID = id
            idsCount += 1
            idsHasher.combine(id)
        }
        return .init(
            normalizedWidth: Int(layoutManager.boundsWidth.rounded(.toNearestOrAwayFromZero)),
            idsHash: idsHasher.finalize(),
            idsCount: idsCount,
            firstID: firstID,
            lastID: lastID,
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

    struct CacheKey: Hashable {
        let normalizedWidth: Int
        let idsHash: Int
        let idsCount: Int
        let firstID: String?
        let lastID: String?
        let selectedMsgId: String?
    }

    struct Cache: Hashable {
        var key: CacheKey
        var totalHeight: CGFloat
        var rows: [Row]

        struct Row: Hashable {
            let id: String
            let rect: CGRect

            init(_ id: String, rect: CGRect) {
                self.id = id
                self.rect = rect
            }
        }
    }
}
