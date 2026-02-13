import Database
import Services
import SwiftUI
import XUI

struct MsgsScrollViewLayoutConfiguration {
	enum Constants {
		static let bubbleWidthRatio: CGFloat = 0.92
		static let maxBubbleHeight: CGFloat = 600
	}

	let spacing: CGFloat
	let contentInsets: EdgeInsets
	let boundsWidth: CGFloat
	var selectedMsg: SelectedMsg?

	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsWidth: CGFloat) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.boundsWidth = boundsWidth
	}

	var containerWidth: CGFloat {
		boundsWidth - contentInsets.horizontal
	}
}

struct MsgsScrollViewLayout: Layout {
	private let layoutManager: MsgsScrollViewLayoutManager
	private let config: MsgsScrollViewLayoutConfiguration

	init(_ manager: MsgsScrollViewLayoutManager, config: MsgsScrollViewLayoutConfiguration) {
		layoutManager = manager
		self.config = config
	}

	private var layoutCache: MsgsScrollViewLayoutCache {
		layoutManager.cache
	}
}

extension MsgsScrollViewLayout {
	func makeCache(subviews: Subviews) -> Cache {
		calculateCache(for: subviews, proposedWidth: config.containerWidth)
	}

	func sizeThatFits(proposal: ProposedViewSize,
	                  subviews: Subviews,
	                  cache: inout Cache) -> CGSize
	{
		let proposedSize = proposal.replacingUnspecifiedDimensions()
		guard !subviews.isEmpty else {
			return proposedSize
		}

		return CGSize(
			width: proposedSize.width,
			height: max(proposedSize.height, cache.totalHeight)
		)
	}

	func explicitAlignment(of guide: HorizontalAlignment,
	                       in _: CGRect,
	                       proposal _: ProposedViewSize,
	                       subviews _: Subviews,
	                       cache: inout Cache) -> CGFloat?
	{
		guard !cache.layouts.isEmpty else { return nil }

		switch guide {
		case .leading:
			return config.contentInsets.leading
		case .trailing:
			return config.boundsWidth - config.contentInsets.trailing
		case .center:
			return config.boundsWidth / 2
		default:
			return nil
		}
	}

	func placeSubviews(in _: CGRect,
	                   proposal _: ProposedViewSize,
	                   subviews: Subviews,
	                   cache: inout Cache)
	{
		guard cache.layouts.count == subviews.count else {
			return
		}

		for (index, subview) in subviews.enumerated() {
			let layout = cache.layouts[index]
			let value = subview[MsgLayoutValueKey.self]

			subview.place(
				at: layout.position,
				anchor: value.anchor,
				proposal: ProposedViewSize(layout.size)
			)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		cache = calculateCache(for: subviews, proposedWidth: config.containerWidth)
	}
}

// MARK: - Cache Calculation

extension MsgsScrollViewLayout {
	private func calculateCache(for subviews: Subviews, proposedWidth: CGFloat) -> Cache {
		let signatureHash = makeLayoutSignature(subviews: subviews, proposedWidth: proposedWidth)

		if let cachedLayout = getValidCachedLayout(
			for: subviews.count,
			boundsWidth: config.boundsWidth,
			signatureHash: signatureHash
		) {
			return cachedLayout
		}

		// Calculate new layout
		let (layouts, totalHeight) = calculateCellLayouts(
			for: subviews,
			proposedWidth: proposedWidth
		)

		let newCache = Cache(
			totalHeight: totalHeight,
			layouts: layouts,
			signatureHash: signatureHash
		)

		// Store in cache
		layoutCache.setCache(
			newCache,
			boundsWidth: config.boundsWidth,
			signatureHash: signatureHash
		)
		return newCache
	}

	private func getValidCachedLayout(for subviewsCount: Int,
	                                  boundsWidth: CGFloat,
	                                  signatureHash: Int) -> Cache?
	{
		guard
			let cachedLayout = layoutCache.cache(
				for: subviewsCount,
				boundsWidth: boundsWidth,
				signatureHash: signatureHash
			)
		else {
			return nil
		}
		return cachedLayout
	}

	private func calculateCellLayouts(for subviews: Subviews,
	                                  proposedWidth: CGFloat) -> ([Cache.CellLayout], CGFloat)
	{
		var layouts: [Cache.CellLayout] = []
		layouts.reserveCapacity(subviews.count)

		var currentY = config.contentInsets.top

		for (index, subview) in subviews.enumerated() {
			let value = subview[MsgLayoutValueKey.self]

			let size = getOrCalculateSize(
				for: value,
				subview: subview,
				proposedWidth: proposedWidth
			)

			let xPosition = calculateXPosition(
				for: value.recipient,
				bubbleWidth: size.width
			)

			let position = CGPoint(x: xPosition, y: currentY)
			let layout = Cache.CellLayout(value.uid, size, position)

			layouts.append(layout)
			currentY += size.height + config.spacing
		}

		let totalHeight = calculateTotalHeight(sizes: layouts.map(\.size))
		return (layouts, totalHeight)
	}
}

// MARK: - Size Calculation & Caching

extension MsgsScrollViewLayout {
	private func getOrCalculateSize(for layoutValue: MsgLayoutValue,
	                                subview: LayoutSubview,
	                                proposedWidth: CGFloat) -> CGSize
	{
		let cacheKey = makeSizeCacheKey(
			layoutValue: layoutValue,
			proposedWidth: proposedWidth
		)

		if let cachedSize = layoutCache.size(for: cacheKey) {
			return cachedSize
		}

		let calculatedSize = calculateOptimalSize(
			for: subview,
			layoutValue: layoutValue,
			proposedWidth: proposedWidth
		)
		layoutCache.setSize(calculatedSize, for: cacheKey)
		return calculatedSize
	}

	private func calculateOptimalSize(for subview: LayoutSubview,
	                                  layoutValue: MsgLayoutValue,
	                                  proposedWidth: CGFloat) -> CGSize
	{
		// Determine container width ratio based on attachments
		let containerWidthRatio: CGFloat = switch layoutValue.attachmentsCount {
		case 0:
			1.0
		case 1:
			0.7
		default:
			0.8
		}

		let containerWidth = proposedWidth * containerWidthRatio
		let targetWidth = containerWidth * MsgsScrollViewLayoutConfiguration.Constants
			.bubbleWidthRatio

		// Calculate size with height constraint
		let proposedViewSize = ProposedViewSize(
			width: targetWidth,
			height: .infinity
		)

		let dimension = subview.sizeThatFits(proposedViewSize)

		// Cap height to prevent overly large messages
		let finalHeight = min(
			dimension.height,
			MsgsScrollViewLayoutConfiguration.Constants.maxBubbleHeight
		)

		return CGSize(width: dimension.width, height: finalHeight)
	}

	private func makeSizeCacheKey(layoutValue: MsgLayoutValue,
	                              proposedWidth: CGFloat) -> String
	{
		let widthKey = String(format: "%.0f", proposedWidth)
		return
			"\(layoutValue.uid)|\(layoutValue.attachmentsCount)|\(layoutValue.recipient.rawValue)|\(widthKey)|\(Int(config.boundsWidth.rounded()))"
	}
}

// MARK: - Positioning

extension MsgsScrollViewLayout {
	private func calculateXPosition(for recipient: MsgRecipient,
	                                bubbleWidth _: CGFloat) -> CGFloat
	{
		let contentWidth = config.boundsWidth

		switch recipient {
		case .send:
			return contentWidth - config.contentInsets.trailing

		case .receive:
			return config.contentInsets.leading

		case .assistant:
			// Center the bubble
			return contentWidth / 2
		}
	}

	private func calculateTotalHeight(sizes: [CGSize]) -> CGFloat {
		guard !sizes.isEmpty else { return 0 }

		let contentHeight = sizes.reduce(0) { $0 + $1.height }
		let totalSpacing = config.spacing * CGFloat(max(0, sizes.count - 1))

		return config.contentInsets.vertical + contentHeight + totalSpacing
	}
}

// MARK: - Layout Signature

extension MsgsScrollViewLayout {
	private func makeLayoutSignature(subviews: Subviews,
	                                 proposedWidth: CGFloat) -> Int
	{
		var hasher = Hasher()

		// Combine configuration
		hasher.combine(Int(proposedWidth.rounded()))
		hasher.combine(config.spacing)
		hasher.combine(config.contentInsets.top)
		hasher.combine(config.contentInsets.leading)
		if let selectedMsg = layoutManager.selectedMsg {
			hasher.combine(selectedMsg.id)
		}
		// Combine subview properties
		for subview in subviews {
			let value = subview[MsgLayoutValueKey.self]
			hasher.combine(value.uid)
			hasher.combine(value.recipient.rawValue)
			hasher.combine(value.attachmentsCount)
		}
		return hasher.finalize()
	}
}

// MARK: - Cache Structures

extension MsgsScrollViewLayout {
	struct Cache: Hashable, Equatable {
		var totalHeight: CGFloat
		var layouts: [CellLayout]
		var signatureHash: Int

		struct CellLayout: Equatable, Hashable {
			let id: String
			let size: CGSize
			let position: CGPoint

			init(_ id: String, _ size: CGSize, _ position: CGPoint) {
				self.id = id
				self.size = size
				self.position = position
			}

			var frame: CGRect {
				CGRect(origin: position, size: size)
			}
		}
	}
}
