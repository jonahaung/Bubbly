//
//  MsgsScrollViewLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import Database
import Services
import SwiftUI
import XUI

private enum LayoutConstants {
	static let bubbleWidthRatio: CGFloat = 0.9
	static let minimumContainerWidth: CGFloat = 1.0
}

struct MsgsScrollViewLayoutConfiguration: Sendable {
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

	private let config: MsgsScrollViewLayoutConfiguration
	private let layoutCache: MsgsScrollViewLayoutCache

	init(
		config: MsgsScrollViewLayoutConfiguration,
		layoutCache: MsgsScrollViewLayoutCache
	) {
		self.config = config
		self.layoutCache = layoutCache
	}
}

extension MsgsScrollViewLayout {
	func makeCache(subviews: Subviews) -> Cache {
		calculateCache(for: subviews)
	}

	func sizeThatFits(
		proposal _: ProposedViewSize,
		subviews _: Subviews,
		cache: inout Cache
	) -> CGSize {
		guard !cache.layouts.isEmpty else {
			return CGSize(width: config.boundsWidth, height: config.contentInsets.vertical)
		}

		return CGSize(width: config.boundsWidth, height: cache.totalHeight)
	}

	func placeSubviews(
		in _: CGRect,
		proposal _: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard config.containerWidth >= LayoutConstants.minimumContainerWidth else { return }

		let count = min(subviews.count, cache.layouts.count)
		guard count > 0 else { return }
		let layouts = cache.layouts
		let zipped = zip(subviews, layouts)
		for (subview, layout) in zipped.reversed() {
			placeSubview(subview, with: layout)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		let newValues = subviews.map { $0[MsgLayoutValueKey.self] }.map(\.uid)
		let oldValues = cache.layouts.map(\.id)
		let needsUpdate = newValues != oldValues || cache.boundsWidth != config.boundsWidth
		guard needsUpdate else { return }
		cache = calculateCache(for: subviews)
	}
}

extension MsgsScrollViewLayout {
	private func calculateCache(for subviews: Subviews) -> Cache {
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
			boundsWidth: config.boundsWidth
		)
		layoutCache.setCache(newCache)
		return newCache
	}

	private func getValidCachedLayout(for subviews: Subviews) -> Cache? {
		guard let cachedLayout = layoutCache.cache(for: config.boundsWidth),
			  cachedLayout.layouts.count == subviews.count
		else {
			return nil
		}
		return cachedLayout
	}

	private func calculateCellLayouts(for subviews: Subviews) -> ([CellLayout], CGFloat) {
		var layouts: [CellLayout] = []
		layouts.reserveCapacity(subviews.count)
		let subviewValues = subviews.map { ($0, $0[MsgLayoutValueKey.self]) }
		let subviewValueSizes = subviewValues.map { ($0.0, $0.1, getOrCalculateSize(for: $0.1.uid, subview: $0.0)) }
		let totalheight = calculateTotalHeight(sizes: subviewValueSizes.map(\.2))
		var currentY = config.contentInsets.top
		for (subview, value, size) in subviewValueSizes {
			let layout = calculateCellLayout(for: subview, value: value, size: size, currentY: currentY)
			layouts.append(layout)
			currentY += size.height + config.spacing
		}
		return (layouts, totalheight)
	}

	private func calculateCellLayout(
		for _: LayoutSubview,
		value: MsgLayoutValue,
		size: CGSize,
		currentY: CGFloat
	) -> CellLayout {
		let position = calculatePosition(for: value, size: size, currentY: currentY)
		return CellLayout(value.uid, size, position)
	}
}

extension MsgsScrollViewLayout {
	private func getOrCalculateSize(for messageID: String, subview: LayoutSubview) -> CGSize {
		if let cachedSize = layoutCache.size(for: messageID) {
			return cachedSize
		}

		let calculatedSize = calculateOptimalSize(for: subview)
		layoutCache.setSize(calculatedSize, for: messageID)
		return calculatedSize
	}

	private func calculateOptimalSize(for subview: LayoutSubview) -> CGSize {
		let targetWidth = config.containerWidth * LayoutConstants.bubbleWidthRatio
		let proposedViewSize = ProposedViewSize(width: targetWidth, height: nil)
		let sizeThatFit = subview.sizeThatFits(proposedViewSize)
		return .init(width: sizeThatFit.width, height: sizeThatFit.height)
	}
}

extension MsgsScrollViewLayout {
	private func calculatePosition(
		for message: MsgLayoutValue,
		size: CGSize,
		currentY: CGFloat
	) -> CGPoint {
		let xPosition = calculateXPosition(for: message.recipient, bubbleWidth: size.width)
		return CGPoint(x: xPosition, y: currentY)
	}

	private func calculateXPosition(for recipient: MsgRecipient, bubbleWidth: CGFloat) -> CGFloat {
		switch recipient {
			case .send:
				config.containerSize.width - bubbleWidth - config.contentInsets.trailing
			case .receive:
				// Left aligned
				config.contentInsets.leading
			case .none:
				// Centered
				config.contentInsets.leading + (config.containerWidth - bubbleWidth) / 2
		}
	}
}

extension MsgsScrollViewLayout {
	private func calculateTotalHeight(sizes: [CGSize]) -> CGFloat {
		let contentHeight = sizes.reduce(0) { $0 + $1.height }
		let totalSpacing = config.spacing * CGFloat(max(0, sizes.count - 1))
		return config.contentInsets.vertical + contentHeight + totalSpacing
	}
}
extension MsgsScrollViewLayout {
	private func placeSubview(_ subview: LayoutSubview, with layout: CellLayout) {
		subview.place(
			at: layout.position,
			anchor: .topLeading,
			proposal: ProposedViewSize(layout.size)
		)
	}
}
extension MsgsScrollViewLayout.Cache {
	static func empty(boundsWidth: CGFloat = 0, contentInsets: EdgeInsets = .init()) -> Self {
		.init(
			totalHeight: contentInsets.vertical,
			layouts: [],
			boundsWidth: boundsWidth
		)
	}
}
