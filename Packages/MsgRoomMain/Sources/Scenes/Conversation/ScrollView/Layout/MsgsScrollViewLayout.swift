//
//  MsgsScrollViewLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import SwiftUI
import XUI
import Services
import Database

// MARK: - Layout Configuration
private enum LayoutConstants {
	static let bubbleWidthRatio: CGFloat = 0.9
	static let minimumContainerWidth: CGFloat = 1.0
}

struct MsgsScrollViewLayoutConfiguration {
	let spacing: CGFloat
	let contentInsets: EdgeInsets
	let containerSize: CGSize
	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, containerSize: CGSize) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.containerSize = containerSize
	}
	var containerWidth: CGFloat { containerSize.width - contentInsets.horizontal }
	var boundsWidth: CGFloat { containerSize.width }
}
struct MsgsScrollViewLayout: Layout {

	// MARK: - Properties
	private let config: MsgsScrollViewLayoutConfiguration
	private let cacheContainer: ChatCache

	// MARK: - Initialization
	init(
		config: MsgsScrollViewLayoutConfiguration,
		cacheContainer: ChatCache
	) {
		self.config = config
		self.cacheContainer = cacheContainer
	}
}

// MARK: - Layout Protocol Implementation
extension MsgsScrollViewLayout {

	func makeCache(subviews: Subviews) -> Cache {
		calculateCache(for: subviews)
	}

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGSize {

		guard config.containerWidth >= LayoutConstants.minimumContainerWidth else {
			return .zeroSize
		}

		guard !cache.layouts.isEmpty else {
			return CGSize(width: config.containerSize.width, height: config.contentInsets.vertical)
		}

		return CGSize(width: config.boundsWidth, height: cache.totalHeight)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard config.containerWidth >= LayoutConstants.minimumContainerWidth else { return }

		let count = min(subviews.count, cache.layouts.count)
		guard count > 0 else { return }
		let layouts = cache.layouts
		let zipped = zip(subviews, layouts)
		zipped.reversed().forEach { (subview, layout) in
			placeSubview(subview, with: layout)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		let newValues = subviews.map { $0[MsgLayoutValueKey.self]}.map { $0.uid }
		let oldValues = cache.layouts.map { $0.id }
		let needsUpdate = newValues != oldValues || cache.boundsWidth != config.boundsWidth
		guard needsUpdate else { return }
		cache = calculateCache(for: subviews)
	}
}

// MARK: - Cache Calculation
private extension MsgsScrollViewLayout {

	func calculateCache(for subviews: Subviews) -> Cache {
		guard !subviews.isEmpty else {
			return .empty(boundsWidth: config.boundsWidth, contentInsets: config.contentInsets)
		}
		// Check for valid cached layout
		if let cachedLayout = getValidCachedLayout(for: subviews) {
			return cachedLayout
		}

		// Calculate new layout
		let (layouts, totalHeight) = calculateCellLayouts(for: subviews)

		let newCache = Cache(
			totalHeight: totalHeight,
			layouts: layouts,
			boundsWidth:  config.boundsWidth
		)
		cacheContainer.layout.setCache(newCache)
		return newCache
	}

	func getValidCachedLayout(for subviews: Subviews) -> Cache? {
		guard let cachedLayout = cacheContainer.layout.cache(for:  config.boundsWidth),
			  cachedLayout.layouts.count == subviews.count else {
			return nil
		}
		return cachedLayout
	}

	func calculateCellLayouts(for subviews: Subviews) -> ([CellLayout], CGFloat) {
		var layouts: [CellLayout] = []
		layouts.reserveCapacity(subviews.count)
		let subviewValues = subviews.map{ ($0, $0[MsgLayoutValueKey.self]) }
		let subviewValueSizes = subviewValues.map{ ($0.0, $0.1, getOrCalculateSize(for: $0.1.uid, subview: $0.0)) }
		let totalheight = calculateTotalHeight(sizes: subviewValueSizes.map(\.2))

		var currentY = config.contentInsets.top
		for (subview, value, size) in subviewValueSizes {
			let layout = calculateCellLayout(for: subview, value: value, size: size, currentY: currentY)
			layouts.append(layout)
			currentY += size.height + config.spacing
		}
		return (layouts, totalheight)
	}

	func calculateCellLayout(for subview: LayoutSubview, value: MsgLayoutValue, size: CGSize, currentY: CGFloat) -> CellLayout {
		let position = calculatePosition(for: value, size: size, currentY: currentY)
		return CellLayout(value.uid, size, position)
	}
}

// MARK: - Size Calculation
private extension MsgsScrollViewLayout {

	func getOrCalculateSize(for messageID: String, subview: LayoutSubview) -> CGSize {
		if let cachedSize = cacheContainer.layout.size(for: messageID) {
			return cachedSize
		}

		let calculatedSize = calculateOptimalSize(for: subview)
		cacheContainer.layout.setSize(calculatedSize, for: messageID)
		return calculatedSize
	}

	func calculateOptimalSize(for subview: LayoutSubview) -> CGSize {
		let targetWidth =  config.containerWidth * LayoutConstants.bubbleWidthRatio
		let proposedViewSize = ProposedViewSize(width: targetWidth, height: nil)
		let sizeThatFit = subview.sizeThatFits(proposedViewSize)
		return .init(width: sizeThatFit.width, height: sizeThatFit.height)
	}
}

// MARK: - Position Calculation
private extension MsgsScrollViewLayout {

	func calculatePosition(
		for message: MsgLayoutValue,
		size: CGSize,
		currentY: CGFloat
	) -> CGPoint {
		let xPosition = calculateXPosition(for: message.recipient, bubbleWidth: size.width)
		return CGPoint(x: xPosition, y: currentY)
	}

	func calculateXPosition(for recipient: MsgRecipient, bubbleWidth: CGFloat) -> CGFloat {
		switch recipient {
		case .send:
			// Right aligned
			return  config.contentInsets.leading +  config.containerWidth - bubbleWidth
		case .receive:
			// Left aligned
			return  config.contentInsets.leading
		case .none:
			// Centered
			return  config.contentInsets.leading + ( config.containerWidth - bubbleWidth) / 2
		}
	}
}

// MARK: - Height Calculation
private extension MsgsScrollViewLayout {

//	func calculateTotalHeight(layouts: [CellLayout], subviewCount: Int) -> CGFloat {
//		let contentHeight = layouts.reduce(0) { $0 + $1.size.height }
//		let totalSpacing =  config.spacing * CGFloat(max(0, subviewCount - 1))
//		return  max(config.minSize.height, config.contentInsets.vertical + contentHeight + totalSpacing)
//	}

	func calculateTotalHeight(sizes: [CGSize]) -> CGFloat {
		let contentHeight = sizes.reduce(0) { $0 + $1.height }
		let totalSpacing =  config.spacing * CGFloat(max(0, sizes.count - 1))
		return  config.contentInsets.vertical + contentHeight + totalSpacing
	}
}

// MARK: - Subview Placement
private extension MsgsScrollViewLayout {

	func placeSubview(_ subview: LayoutSubview, with layout: CellLayout) {
		subview.place(
			at: layout.position,
			anchor: .topLeading,
			proposal: ProposedViewSize(layout.size)
		)
	}
}

// MARK: - Cache Extension
extension MsgsScrollViewLayout.Cache {

	static func empty(boundsWidth: CGFloat, contentInsets: EdgeInsets) -> Self {
		.init(
			totalHeight: contentInsets.vertical,
			layouts: [],
			boundsWidth: boundsWidth
		)
	}
}

// MARK: - CGSize Extension
private extension CGSize {
	static var zeroSize: CGSize { .init(width: 0, height: 0) }
}
