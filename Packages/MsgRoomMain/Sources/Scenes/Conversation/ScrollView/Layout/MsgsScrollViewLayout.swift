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

// MARK: - Main Layout
struct MsgsScrollViewLayout: Layout {

	// MARK: - Properties
	private let spacing: CGFloat
	private let boundsWidth: CGFloat
	private let containerWidth: CGFloat
	private let cacheContainer: ChatCache
	private let contentInsets: EdgeInsets
	private let onUpdateHeight: @Sendable (CGFloat) -> Void

	// MARK: - Initialization
	init(
		spacing: CGFloat,
		boundsWidth: CGFloat,
		cacheContainer: ChatCache,
		contentInsets: EdgeInsets,
		onUpdateHeight: @Sendable @escaping (CGFloat) -> Void
	) {
		self.spacing = spacing
		self.boundsWidth = boundsWidth
		self.containerWidth = boundsWidth - contentInsets.horizontal
		self.cacheContainer = cacheContainer
		self.contentInsets = contentInsets
		self.onUpdateHeight = onUpdateHeight
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
		guard containerWidth >= LayoutConstants.minimumContainerWidth else {
			return .zeroSize
		}

		guard !cache.layouts.isEmpty else {
			return CGSize(width: boundsWidth, height: contentInsets.vertical)
		}

		return CGSize(width: boundsWidth, height: cache.totalHeight)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard containerWidth >= LayoutConstants.minimumContainerWidth else { return }

		let count = min(subviews.count, cache.layouts.count)
		guard count > 0 else { return }
		let layouts = cache.layouts
		subviews.enumerated().forEach { (index, subview) in
			let layout = layouts[index]
			placeSubview(subview, with: layout)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		let newValues = subviews.map{ $0[MsgLayoutValueKey.self]}.map{ $0.uid }
		let oldValues = cache.layouts.map{ $0.id }
		let needsUpdate = newValues != oldValues || cache.boundsWidth != boundsWidth
		guard needsUpdate else { return }
		cache = calculateCache(for: subviews)
	}
}

// MARK: - Cache Calculation
private extension MsgsScrollViewLayout {

	func calculateCache(for subviews: Subviews) -> Cache {
		guard !subviews.isEmpty else {
			return .empty(boundsWidth: boundsWidth, contentInsets: contentInsets)
		}

		// Check for valid cached layout
		if let cachedLayout = getValidCachedLayout(for: subviews) {
			return cachedLayout
		}

		// Calculate new layout
		let layouts = calculateCellLayouts(for: subviews)
		let totalHeight = calculateTotalHeight(layouts: layouts, subviewCount: subviews.count)
		if let oldHeight = cacheContainer.layout.cache(for: boundsWidth)?.totalHeight, oldHeight != totalHeight {
			let diff = totalHeight - oldHeight
			onUpdateHeight(diff)
		}
		let newCache = Cache(
			totalHeight: totalHeight,
			layouts: layouts,
			boundsWidth: boundsWidth
		)
		cacheContainer.layout.setCache(newCache)
		return newCache
	}

	func getValidCachedLayout(for subviews: Subviews) -> Cache? {
		guard let cachedLayout = cacheContainer.layout.cache(for: boundsWidth),
			  cachedLayout.layouts.count == subviews.count else {
			return nil
		}
		return cachedLayout
	}

	func calculateCellLayouts(for subviews: Subviews) -> [CellLayout] {
		var layouts: [CellLayout] = []
		var currentY = contentInsets.top

		layouts.reserveCapacity(subviews.count)

		for subview in subviews {
			let layout = calculateCellLayout(for: subview, currentY: currentY)
			layouts.append(layout)
			currentY += layout.size.height + spacing
		}

		return layouts
	}

	func calculateCellLayout(for subview: LayoutSubview, currentY: CGFloat) -> CellLayout {
		let layoutValue = subview[MsgLayoutValueKey.self]
		let size = getOrCalculateSize(for: layoutValue.uid, subview: subview)
		let position = calculatePosition(for: layoutValue, size: size, currentY: currentY)
		return CellLayout(layoutValue.uid, size, position)
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
		let targetWidth = containerWidth * LayoutConstants.bubbleWidthRatio
		let viewDimension = subview.dimensions(in: .init(width: targetWidth, height: nil))
		return .init(width: viewDimension.width, height: viewDimension.height)
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
			return contentInsets.leading + containerWidth - bubbleWidth
		case .receive:
			// Left aligned
			return contentInsets.leading
		case .none:
			// Centered
			return contentInsets.leading + (containerWidth - bubbleWidth) / 2
		}
	}
}

// MARK: - Height Calculation
private extension MsgsScrollViewLayout {

	func calculateTotalHeight(layouts: [CellLayout], subviewCount: Int) -> CGFloat {
		let contentHeight = layouts.reduce(0) { $0 + $1.size.height }
		let totalSpacing = spacing * CGFloat(max(0, subviewCount - 1))
		return contentInsets.vertical + contentHeight + totalSpacing
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
