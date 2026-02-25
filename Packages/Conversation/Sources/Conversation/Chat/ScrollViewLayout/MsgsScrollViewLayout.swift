import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayoutConfiguration {
	let superTopSpace = CGFloat(50)
	let spacing: CGFloat
	let contentInsets: EdgeInsets
	var boundsWidth: CGFloat

	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsWidth: CGFloat) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.boundsWidth = boundsWidth
	}
}

struct MsgsScrollViewLayout: Layout {
	private let layoutManager: MsgsScrollViewLayoutManager
	private var config: MsgsScrollViewLayoutConfiguration { layoutManager.config }

	init(_ manager: MsgsScrollViewLayoutManager) {
		layoutManager = manager
	}
}

extension MsgsScrollViewLayout {

	func makeCache(subviews: Subviews) -> Cache {
		calculateCache(for: subviews, proposedWidth: config.boundsWidth)
	}

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGSize {
		let proposedSize = proposal.replacingUnspecifiedDimensions()
		guard !subviews.isEmpty else {
			return proposedSize
		}
		return CGSize(
			width: proposedSize.width,
			height: max(proposedSize.height, cache.totalHeight)
		)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal proposedViewSize: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard cache.layouts.count == subviews.count else {
			return
		}
		let x = bounds.minX + config.contentInsets.leading
		for (index, subview) in subviews.enumerated() {
			if let layout = cache.layouts[safe: index] {
				subview.place(
					at: .init(x: x, y: layout.y),
					anchor: .topLeading,
					proposal: ProposedViewSize(layout.size)
				)
			}
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		let key = makeCacheKey(subviews: subviews)
		if cache.key != key {
			cache = calculateCache(
				for: subviews,
				proposedWidth: config.boundsWidth
			)
		}
	}
}

extension MsgsScrollViewLayout {

	private func calculateCache(
		for subviews: Subviews,
		proposedWidth: CGFloat
	) -> Cache {

		let signatureHash = makeCacheKey(
			subviews: subviews
		)

		if let cached = layoutManager.cache(for: signatureHash) {
			return cached
		}

		let layouts = calculateCellLayouts(
			for: subviews,
			proposedWidth: proposedWidth
		)

		let totalHeight = layouts.map(\.size).reduce(CGFloat.zero) { partialResult, size in
			partialResult + size.height + config.spacing
		} + config.contentInsets.vertical + config.superTopSpace


		let newCache = Cache(
			totalHeight: totalHeight,
			layouts: layouts, key: signatureHash
		)
		layoutManager.set(cache: newCache, for: signatureHash)
		return newCache
	}

	private func calculateCellLayouts(
		for subviews: Subviews,
		proposedWidth: CGFloat
	) -> [Cache.CellLayout] {

		var layouts: [Cache.CellLayout] = []
		layouts.reserveCapacity(subviews.count)
		var currentY = config.contentInsets.top + config.superTopSpace
		let spacing = config.spacing

		for subview in subviews {
			let value = subview[MsgLayoutValueKey.self]

			let size = getOrCalculateSize(
				for: value,
				subview: subview,
				proposedWidth: proposedWidth
			)
			layouts.append(.init(value.uid, size, currentY))
			currentY += (size.height + spacing)
		}
		return layouts
	}
}

extension MsgsScrollViewLayout {

	private func getOrCalculateSize(
		for layoutValue: MsgLayoutValue,
		subview: LayoutSubview,
		proposedWidth: CGFloat
	) -> CGSize {
		let value = subview[MsgLayoutValueKey.self]
		let key = SubviewKey(
			uid: value.id,
			isSelected: value.id == layoutManager.selectedMsg?.id,
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

	private func calculateXPosition(
		for recipient: MsgRecipient,
		bubbleWidth width: CGFloat
	) -> CGFloat {
		let contentWidth = config.boundsWidth
		switch recipient {
		case .send:
			return contentWidth - width - config.contentInsets.trailing
		case .receive:
			return config.contentInsets.leading
		case .assistant:
			return (contentWidth - width) / 2
		}
	}
}

extension MsgsScrollViewLayout {

	private func makeCacheKey(
		subviews: LayoutSubviews
	) -> CacheKey {
		return .init(
			boundsWidth: config.boundsWidth,
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

	struct CacheKey: Hashable {
		let boundsWidth: CGFloat
		let subviewKeys: [String]
		let selectedMsgId: String?
	}

	struct Cache: Hashable {
		var totalHeight: CGFloat
		var layouts: [CellLayout]
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
