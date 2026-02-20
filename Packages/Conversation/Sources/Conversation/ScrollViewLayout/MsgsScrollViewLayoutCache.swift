import CoreGraphics

final class MsgsScrollViewLayoutCache {
	enum Invalidation {
		case all
		case specificId(String)
	}

	// MARK: Height + Offset Maps

	private(set) var heights: [String: CGFloat] = [:]
	private(set) var offsets: [String: CGFloat] = [:]

	private(set) var orderedIDs: [String] = []
	private var layoutCaches: [LayoutCacheKey: MsgsScrollViewLayout.Cache] = [:]
	private var sizeCaches: [String: CGSize] = [:]

	private struct LayoutCacheKey: Hashable {
		let count: Int
		let boundsWidth: CGFloat
		let signatureHash: Int
	}

	// MARK: Height Management

	func setHeight(_ height: CGFloat, for id: String) {
		heights[id] = height
	}

	func height(for id: String) -> CGFloat {
		heights[id] ?? 0
	}

	func offset(for id: String) -> CGFloat {
		offsets[id] ?? 0
	}

	// MARK: Full Recompute (Fallback Only)

	func recomputeAll(with ids: [String], spacing: CGFloat, topInset: CGFloat) {
		orderedIDs = ids

		var currentY = topInset

		for id in ids {
			offsets[id] = currentY
			currentY += (heights[id] ?? 0) + spacing
		}
	}

	// MARK: Incremental Append

	func append(
		ids: [String],
		spacing: CGFloat
	) {
		guard let last = orderedIDs.last else {
			orderedIDs = ids
			return
		}

		var currentY = offset(for: last) + height(for: last) + spacing

		for id in ids {
			offsets[id] = currentY
			currentY += (heights[id] ?? 0) + spacing
		}

		orderedIDs.append(contentsOf: ids)
	}

	// MARK: Incremental Prepend

	func prepend(
		ids: [String],
		spacing: CGFloat,
		topInset: CGFloat
	) -> CGFloat {

		let insertedHeight = ids.reduce(0) {
			$0 + (heights[$1] ?? 0)
		} + CGFloat(ids.count) * spacing

		// Shift existing offsets
		for id in orderedIDs {
			offsets[id, default: 0] += insertedHeight
		}

		// Insert new offsets
		var currentY = topInset
		for id in ids {
			offsets[id] = currentY
			currentY += (heights[id] ?? 0) + spacing
		}

		orderedIDs.insert(contentsOf: ids, at: 0)

		return insertedHeight
	}

	// MARK: Incremental Update

	func updateHeight(
		for id: String,
		newHeight: CGFloat,
		spacing: CGFloat
	) {
		let oldHeight = heights[id] ?? 0
		let delta = newHeight - oldHeight
		guard delta != 0 else { return }

		heights[id] = newHeight

		guard let index = orderedIDs.firstIndex(of: id) else { return }

		for i in index + 1..<orderedIDs.count {
			offsets[orderedIDs[i], default: 0] += delta
		}
	}

	func invalidate(_ invalidation: Invalidation) {
		switch invalidation {
		case .all:
			heights.removeAll(keepingCapacity: true)
			offsets.removeAll(keepingCapacity: true)
			orderedIDs.removeAll(keepingCapacity: true)
			layoutCaches.removeAll(keepingCapacity: true)
			sizeCaches.removeAll(keepingCapacity: true)
		case .specificId(let id):
			heights[id] = nil
			offsets[id] = nil
			orderedIDs.removeAll(where: { $0 == id })
			layoutCaches.removeAll(keepingCapacity: true)
			sizeCaches = sizeCaches.filter { !$0.key.contains(id) }
		}
	}

	func setCache(_ cache: MsgsScrollViewLayout.Cache,
	              boundsWidth: CGFloat,
	              signatureHash: Int)
	{
		layoutCaches[
			.init(
				count: cache.layouts.count,
				boundsWidth: boundsWidth,
				signatureHash: signatureHash
			)
		] = cache
	}

	func cache(for count: Int,
	           boundsWidth: CGFloat,
	           signatureHash: Int) -> MsgsScrollViewLayout.Cache?
	{
		layoutCaches[
			.init(
				count: count,
				boundsWidth: boundsWidth,
				signatureHash: signatureHash
			)
		]
	}

	func setSize(_ size: CGSize, for key: String) {
		sizeCaches[key] = size
	}

	func size(for key: String) -> CGSize? {
		sizeCaches[key]
	}
}
