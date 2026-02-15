//
//  RecyclingScrollingLazyView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 16/2/26.
//

import SwiftUI

struct RecyclingScrollingLazyView<
	ID: Hashable,
	Content: View
>: View {

	let rowIDs: [ID]
	@ViewBuilder var content: (ID) -> Content

	@State private var visibleRange: Range<Int> = 0..<1
	@State private var heightCache: [Int: CGFloat] = [:]
	@State private var cumulativeOffsets: [CGFloat] = []
	@State private var totalHeight: CGFloat = 0

	struct RowData: Identifiable {
		let fragmentID: Int
		let index: Int
		let value: ID
		var id: Int { fragmentID }
	}

	var visibleRows: [RowData] {
		guard !rowIDs.isEmpty else { return [] }

		let lower = max(0, visibleRange.lowerBound)
		let upper = min(rowIDs.count, visibleRange.upperBound)
		let range = lower..<max(lower + 1, upper)

		return range.map {
			RowData(
				fragmentID: $0 % max(range.count, 1),
				index: $0,
				value: rowIDs[$0]
			)
		}
	}

	var body: some View {
		ScrollView(.vertical) {
			DynamicOffsetLayout(
				totalHeight: totalHeight,
				offsets: offsetsDictionary()
			) {
				ForEach(visibleRows) { row in
					content(row.value)
						.background(
							GeometryReader { geo in
								Color.clear
									.onAppear {
										updateHeight(
											geo.size.height,
											for: row.index
										)
									}
									.onChange(of: geo.size.height) { newValue in
										updateHeight(
											newValue,
											for: row.index
										)
									}
							}
						)
						.layoutValue(
							key: LayoutIndex.self,
							value: row.index
						)
				}
			}
		}
		.onScrollGeometryChange(
			for: Range<Int>.self,
			of: { geo in
				computeVisibleRange(in: geo.visibleRect)
			},
			action: { _, newRange in
				visibleRange = newRange
			}
		)
		.onAppear {
			recomputeOffsets()
		}
	}
}

private extension RecyclingScrollingLazyView {

	func updateHeight(_ height: CGFloat, for index: Int) {
		if heightCache[index] == height { return }
		heightCache[index] = height
		recomputeOffsets()
	}

	func recomputeOffsets() {
		var offsets: [CGFloat] = []
		offsets.reserveCapacity(rowIDs.count)

		var running: CGFloat = 0
		for i in 0..<rowIDs.count {
			offsets.append(running)
			running += heightCache[i] ?? 60
		}

		cumulativeOffsets = offsets
		totalHeight = running
	}

	func offsetsDictionary() -> [Int: CGFloat] {
		var dict: [Int: CGFloat] = [:]
		for (index, value) in cumulativeOffsets.enumerated() {
			dict[index] = value
		}
		return dict
	}

	func computeVisibleRange(in rect: CGRect) -> Range<Int> {
		guard !rowIDs.isEmpty else { return 0..<0 }

		let lower = binarySearch(for: rect.minY)
		let upper = binarySearch(for: rect.maxY)

		return lower..<max(lower + 1, upper)
	}

	func binarySearch(for y: CGFloat) -> Int {
		var low = 0
		var high = cumulativeOffsets.count - 1

		while low <= high {
			let mid = (low + high) / 2
			let value = cumulativeOffsets[mid]

			if value < y {
				low = mid + 1
			} else {
				high = mid - 1
			}
		}

		return max(0, min(low, cumulativeOffsets.count - 1))
	}
}
