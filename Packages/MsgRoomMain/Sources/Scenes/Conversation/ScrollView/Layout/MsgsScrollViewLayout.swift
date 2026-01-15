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
	static let bubbleWidthRatio: CGFloat = 0.95
}

struct MsgsScrollViewLayoutConfiguration {

	let spacing: CGFloat
	let contentInsets: EdgeInsets
	private let boundsSize: CGSize

	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsSize: CGSize) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.boundsSize = boundsSize
	}

	var containerWidth: CGFloat { boundsSize.width - contentInsets.horizontal }
	var boundsWidth: CGFloat { boundsSize.width }
}

struct MsgsScrollViewLayout: Layout, Equatable {

	static func == (lhs: MsgsScrollViewLayout, rhs: MsgsScrollViewLayout) -> Bool {
		lhs.config.boundsWidth == rhs.config.boundsWidth
	}

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
		calculateCache(for: subviews, proposedWidth: config.containerWidth)
	}

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGSize {
		let proposedSize = proposal.replacingUnspecifiedDimensions()
		guard subviews.isEmpty == false else {
			return proposedSize
		}
		return CGSize(
			width: proposedSize.width,
			height: max(proposedSize.height, cache.totalHeight)
		)
	}

	func placeSubviews(
		in _: CGRect,
		proposal : ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		let layouts = cache.layouts
		guard layouts.count == subviews.count else {
			return
		}
		let zipped = zip(subviews, layouts)
		for (subview, layout) in zipped {
			let value = subview[MsgLayoutValueKey.self]
			subview.place(
				at: layout.position,
				anchor: value.anchor,
				proposal: .init(layout.size)
			)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		cache = calculateCache(for: subviews, proposedWidth: config.containerWidth)
	}
}

extension MsgsScrollViewLayout {
	private func calculateCache(for subviews: Subviews, proposedWidth: CGFloat) -> Cache {

		if let cachedLayout = getValidCachedLayout(for: subviews) {
			return cachedLayout
		}

		let (layouts, totalHeight) = calculateCellLayouts(
			for: subviews,
			proposedWidth: proposedWidth
		)

		let newCache = Cache(
			totalHeight: totalHeight,
			layouts: layouts
		)
		layoutCache.setCache(newCache)
		return newCache
	}

	private func getValidCachedLayout(for subviews: Subviews) -> Cache? {
		guard let cachedLayout = layoutCache.cache(for: subviews.count) else {
			return nil
		}
		return cachedLayout
	}

	private func calculateCellLayouts(for subviews: Subviews, proposedWidth: CGFloat) -> ([Cache.CellLayout], CGFloat) {
		var layouts: [Cache.CellLayout] = []
		layouts.reserveCapacity(subviews.count)

		var currentY = config.contentInsets.top
		for subview in subviews {
			let value = subview[MsgLayoutValueKey.self]
			let size = getOrCalculateSize(
				for: value,
				subview: subview,
				proposedWidth: proposedWidth
			)

			let xPosition = calculateXPosition(for: value.recipient, bubbleWidth: size.width)
			let position = CGPoint(x: xPosition, y: currentY)
			let layout = Cache.CellLayout(value.uid, size, position)

			layouts.append(layout)
			currentY += size.height + config.spacing
		}
		let totalHeight = calculateTotalHeight(sizes: layouts.map(\.size))
		return (layouts, totalHeight)
	}

}

extension MsgsScrollViewLayout {
	private func getOrCalculateSize(for layoutValue: MsgLayoutValue, subview: LayoutSubview, proposedWidth: CGFloat) -> CGSize {
		let messageID = layoutValue.uid
		if let cachedSize = layoutCache.size(for: messageID) {
			return cachedSize
		}
		let calculatedSize = calculateOptimalSize(
			for: subview,
			layoutValue: layoutValue,
			proposedWidth: proposedWidth
		)
		layoutCache.setSize(calculatedSize, for: messageID)
		return calculatedSize
	}

	private func calculateOptimalSize(for subview: LayoutSubview, layoutValue: MsgLayoutValue, proposedWidth: CGFloat) -> CGSize {
		let containerWidth: CGFloat = {
			if layoutValue.attachmentsCount == 0 {
				return proposedWidth
			}
			return proposedWidth * (layoutValue.attachmentsCount == 1 ? 0.7 : 0.8)
		}()
		let targetWidth = containerWidth * LayoutConstants.bubbleWidthRatio
		let proposedViewSize = ProposedViewSize(width: targetWidth, height: nil)
		let dimension = subview.sizeThatFits(proposedViewSize)
		return .init(width: dimension.width, height: dimension.height)
	}
}

extension MsgsScrollViewLayout {
	private func calculateXPosition(for recipient: MsgRecipient, bubbleWidth: CGFloat) -> CGFloat {
		switch recipient {
		case .send:
			config.boundsWidth - config.contentInsets.trailing
		case .receive:
			config.contentInsets.leading
		case .assistant:
			config.boundsWidth / 2
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
