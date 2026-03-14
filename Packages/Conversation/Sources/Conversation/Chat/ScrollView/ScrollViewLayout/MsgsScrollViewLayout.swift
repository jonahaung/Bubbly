//
//  MsgsScrollViewLayout.swift
//  Conversation
//
//  Created by Aung Ko Min on 9/3/26.
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
		guard layoutManager.config.boundsWidth > 0 else { return .zero }
		let cacheKey = makeCacheKey(subviews: subviews)
		if cache.key != cacheKey { cache = makeCache(subviews: subviews) }
		return CGSize(width: layoutManager.config.boundsWidth, height: cache.totalHeight)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal proposedViewSize: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard layoutManager.config.boundsWidth > 0 else { return }

		let cacheKey = makeCacheKey(subviews: subviews)
		if cache.key != cacheKey { cache = makeCache(subviews: subviews) }

		let minX = bounds.minX + config.contentInsets.leading
		let spacing = config.spacing
		let proposedWidth = layoutManager.boundsWidth

		switch config.layoutDirection {
		case .top:
			var currentY = bounds.minY + config.contentInsets.top + config.additionalTopSpace
			let spacing = config.spacing

			for subview in subviews {
				let value = subview[MsgLayoutValueKey.self]
				let size = getOrCalculateSize(
					for: value,
					subview: subview,
					proposedWidth: proposedWidth
				)
				let origin = CGPoint(x: minX, y: currentY)
				subview.place(at: origin, anchor: .topLeading, proposal: .init(size))
				currentY += size.height + spacing
			}
		case .bottom:
			var currentY = cache.totalHeight - config.contentInsets.bottom
			for subview in subviews.reversed() {
				let value = subview[MsgLayoutValueKey.self]
				let size = getOrCalculateSize(
					for: value,
					subview: subview,
					proposedWidth: proposedWidth
				)

				currentY -= size.height
				let origin = CGPoint(x: minX, y: currentY)
				subview.place(at: origin, anchor: .topLeading, proposal: .init(size))
				currentY -= spacing
			}
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		guard layoutManager.config.boundsWidth > 0 else {
			return
		}
		let key = makeCacheKey(subviews: subviews)
		if cache.key == key {
			layoutManager.trackCacheHit()
			return
		}
		let oldIDs = cache.rows.map(\.id)
		let orderedValues = orderedValues(from: subviews)
		let newIDs = orderedValues.map(\.id)
		if shouldUseIncrementalUpdate(
			oldIDs: oldIDs,
			newIDs: newIDs,
			oldKey: cache.key,
			newKey: key
		) {
			cache = buildIncrementalCache(
				from: cache,
				orderedValues: orderedValues,
				subviews: subviews,
				key: key
			)
			layoutManager.set(cache: cache, for: key)
			layoutManager.trackIncrementalUpdate()
			return
		}
		cache = calculateCache(for: subviews)
		layoutManager.trackFullRebuild()
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
			layoutManager.trackCacheHit()
			return cached
		}

		let rows = calculateCellLayouts(
			for: subviews
		)

		let newCache = Cache(
			key: signatureHash,
			totalHeight: totalHeight(from: rows),
			itemCount: subviews.count,
			rows: rows
		)
		layoutManager.set(cache: newCache, for: signatureHash)
		layoutManager.trackFullRebuild()
		return newCache
	}

	private func calculateCellLayouts(
		for subviews: Subviews
	) -> [Cache.Row] {

		let values = orderedValues(from: subviews)
		var rows = [Cache.Row]()
		rows.reserveCapacity(values.count)
		let proposedWidth = layoutManager.boundsWidth

		let subviewsByID = Dictionary(
			uniqueKeysWithValues: subviews.map { subview in
				let value = subview[MsgLayoutValueKey.self]
				return (value.id, subview)
			}
		)
		for value in values {
			guard let subview = subviewsByID[value.id] else { continue }
			let size = getOrCalculateSize(
				for: value,
				subview: subview,
				proposedWidth: proposedWidth
			)
			rows.append(.init(id: value.id, size: size))
		}
		return rows
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
			signature: layoutValue.signature,
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
		var layoutHasher = Hasher()
		let firstID: String? = {
			guard let subview = subviews.first else {
				return nil
			}
			return subview[MsgLayoutValueKey.self].uid
		}()
		let lastID: String? = {
			guard let subview = subviews.last else {
				return nil
			}
			return subview[MsgLayoutValueKey.self].uid
		}()
		for subview in subviews {
			let value = subview[MsgLayoutValueKey.self]
			layoutHasher.combine(value.uid)
			layoutHasher.combine(value.signature)
		}
		return .init(
			boundsWidth: layoutManager.boundsWidth.int,
			layoutHash: layoutHasher.finalize(),
			idsCount: subviews.count,
			selectedMsgId: layoutManager.selectedMsg?.id,
			firstID: firstID, lastID: lastID
		)
	}
}

extension MsgsScrollViewLayout {
	private func orderedValues(from subviews: Subviews) -> [MsgLayoutValue] {
		switch config.layoutDirection {
		case .top:
			subviews.map { $0[MsgLayoutValueKey.self] }
		case .bottom:
			subviews.reversed().map { $0[MsgLayoutValueKey.self] }
		}
	}

	private func shouldUseIncrementalUpdate(
		oldIDs: [String],
		newIDs: [String],
		oldKey: CacheKey,
		newKey: CacheKey
	) -> Bool {
		guard oldKey.selectedMsgId == newKey.selectedMsgId,
			  oldKey.boundsWidth == newKey.boundsWidth else { return false }
		return detectEdgeMutation(oldIDs: oldIDs, newIDs: newIDs) != nil
	}

	private enum EdgeMutation {
		case edge
	}

	private func detectEdgeMutation(oldIDs: [String], newIDs: [String]) -> EdgeMutation? {
		if newIDs.count > oldIDs.count {
			if Array(newIDs.dropLast(newIDs.count - oldIDs.count)) == oldIDs { return .edge }
			if Array(newIDs.dropFirst(newIDs.count - oldIDs.count)) == oldIDs { return .edge }
			return nil
		}
		if oldIDs.count > newIDs.count {
			if Array(oldIDs.dropLast(oldIDs.count - newIDs.count)) == newIDs { return .edge }
			if Array(oldIDs.dropFirst(oldIDs.count - newIDs.count)) == newIDs { return .edge }
			return nil
		}
		guard oldIDs.isEmpty == false else { return nil }
		if oldIDs.first != newIDs.first, Array(oldIDs.dropFirst()) == Array(newIDs.dropFirst()) {
			return .edge
		}
		if oldIDs.last != newIDs.last, Array(oldIDs.dropLast()) == Array(newIDs.dropLast()) {
			return .edge
		}
		return nil
	}

	private func buildIncrementalCache(
		from oldCache: Cache,
		orderedValues: [MsgLayoutValue],
		subviews: Subviews,
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
		var rows = [Cache.Row]()
		rows.reserveCapacity(orderedValues.count)
		for value in orderedValues {
			if let existing = rowsByID[value.id] {
				rows.append(existing)
			} else if let subview = subviewsByID[value.id] {
				let size = getOrCalculateSize(
					for: value,
					subview: subview,
					proposedWidth: proposedWidth
				)
				rows.append(.init(id: value.id, size: size))
			}
		}
		return Cache(
			key: key,
			totalHeight: totalHeight(from: rows),
			itemCount: rows.count,
			rows: rows
		)
	}

	private func totalHeight(from rows: [Cache.Row]) -> CGFloat {
		rows.reduce(CGFloat.zero) { partialResult, row in
			partialResult + row.size.height + config.spacing
		} + config.contentInsets.vertical + config.additionalTopSpace
	}
}

extension MsgsScrollViewLayout {
	struct SubviewKey: Hashable {
		let uid: String
		let signature: Int
		let isSelected: Bool
		let boundsWidth: CGFloat
	}

	struct CacheKey: Hashable {
		let boundsWidth: Int
		let layoutHash: Int
		let idsCount: Int
		let selectedMsgId: String?
		let firstID: String?
		let lastID: String?
	}

	struct Cache: Hashable {
		var key: CacheKey
		var totalHeight: CGFloat
		var itemCount: Int
		var rows: [Row]

		struct Row: Hashable {
			let id: String
			let size: CGSize
		}
	}
}
