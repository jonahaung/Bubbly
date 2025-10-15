//  MsgsScrollViewLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import SwiftUI
import XUI
import Services
import Database

struct MsgsScrollViewLayout: Layout {

	// MARK: - Configuration

	private let spacing: CGFloat
	private let boundsWidth: CGFloat
	private let cache: ChatCache
	private let contentInsets: EdgeInsets

	init(
		spacing: CGFloat,
		boundsWidth: CGFloat,
		cache: ChatCache,
		contentInsets: EdgeInsets
	) {
		self.spacing = spacing
		self.boundsWidth = boundsWidth
		self.cache = cache
		self.contentInsets = contentInsets
	}

	// MARK: - Computed Properties

	private var containerWidth: CGFloat {
		max(0, boundsWidth - contentInsets.horizontal)
	}

	// Used as a cache key variant for width-dependent layouts
	private var layoutWidthKey: CGFloat { boundsWidth }

	// MARK: - Layout Implementation

	func makeCache(subviews: Subviews) -> Cache {
		Cache(layouts: calculateLayouts(for: subviews))
	}

	func sizeThatFits(
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGSize {
		guard boundsWidth > 0 else {
			return .init(width: 0, height: contentInsets.vertical)
		}
		guard !cache.layouts.isEmpty else {
			return .init(width: boundsWidth, height: contentInsets.vertical)
		}
		let totalHeight = calculateTotalHeight(layouts: cache.layouts, subviewCount: subviews.count)
		return CGSize(width: boundsWidth, height: totalHeight)
	}

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		guard boundsWidth > 0 else { return }

		// Ensure we don't crash on a mismatch between subviews and cached layouts.
		let count = min(subviews.count, cache.layouts.count)
		guard count > 0 else { return }

		for index in 0..<count {
			let subview = subviews[index]
			let layout = cache.layouts[index]
			subview.place(
				at: layout.position,
				anchor: .topLeading,
				proposal: ProposedViewSize(layout.size)
			)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		cache.layouts = calculateLayouts(for: subviews)
	}
}

// MARK: - Private Implementation

private extension MsgsScrollViewLayout {

	func calculateLayouts(for subviews: Subviews) -> [CellLayout] {
		guard !subviews.isEmpty else { return [] }

		var layouts: [CellLayout] = []
		var currentY = contentInsets.top

		layouts.reserveCapacity(subviews.count)

		for subview in subviews {
			let layoutValue = subview[MsgLayoutValueKey.self]
			let layout = calculateLayout(for: layoutValue, subview: subview, currentY: currentY)
			layouts.append(layout)
			currentY += layout.size.height + spacing
		}

		return layouts
	}

	func calculateLayout(
		for layoutValue: MsgLayoutValue,
		subview: LayoutSubview,
		currentY: CGFloat
	) -> CellLayout {
		// Try to get cached layout first
		if let cached = cache.layout.layout(for: layoutValue.uid, boundsWidth: layoutWidthKey) {
			let updatedPosition = calculatePosition(for: layoutValue, size: cached.size, currentY: currentY)

			// Update cache only if position changed
			if cached.position != updatedPosition {
				let updatedLayout = CellLayout(layoutValue.uid, cached.size, updatedPosition)
				cache.layout.setLayout(updatedLayout, for: layoutValue.uid, boundsWidth: layoutWidthKey)
				return updatedLayout
			}
			return cached
		}

		// Calculate new layout
		let size = calculateSize(for: subview)
		let position = calculatePosition(for: layoutValue, size: size, currentY: currentY)
		let layout = CellLayout(layoutValue.uid, size, position)
		cache.layout.setLayout(layout, for: layoutValue.uid, boundsWidth: layoutWidthKey)
		return layout
	}

	func calculateSize(for subview: LayoutSubview) -> CGSize {
		// Bubble max width set to 90% of container width; tweak here if needed
		let targetWidth = containerWidth * 0.9
		return subview.sizeThatFits(.init(width: targetWidth, height: nil))
	}

	func calculatePosition(
		for msg: MsgLayoutValue,
		size: CGSize,
		currentY: CGFloat
	) -> CGPoint {
		let minX: CGFloat = {
			switch msg.recipient {
			case .send:
				// Right aligned within container
				return contentInsets.leading + containerWidth - size.width
			case .receive:
				// Left aligned within container
				return contentInsets.leading
			case .none:
				// Centered within container
				return contentInsets.leading + (containerWidth - size.width) / 2
			}
		}()
		return CGPoint(x: minX, y: currentY)
	}

	func calculateTotalHeight(layouts: [CellLayout], subviewCount: Int) -> CGFloat {
		let contentHeight = layouts.reduce(CGFloat(0)) { $0 + $1.size.height }
		let spacingHeight = spacing * CGFloat(max(0, subviewCount - 1))
		return contentInsets.vertical + contentHeight + spacingHeight
	}
}
