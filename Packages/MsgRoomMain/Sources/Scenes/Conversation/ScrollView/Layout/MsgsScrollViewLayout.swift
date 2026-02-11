//
//  MsgsScrollViewLayout.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

//
//  MsgsScrollViewLayout.swift (Optimized with Background + Diffing)
//  MsgRoomMain
//
//  Refactored for performance
//

import Database
import Services
import SwiftUI
import XUI

private enum LayoutConstants {
	static let bubbleWidthRatio: CGFloat = 0.92
	static let maxBubbleHeight: CGFloat = 600
	#if DEBUG
		static let cacheDebugEnabled = false
	#endif
}

struct MsgsScrollViewLayoutConfiguration {
	let spacing: CGFloat
	let contentInsets: EdgeInsets
	let boundsWidth: CGFloat

	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsWidth: CGFloat) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.boundsWidth = boundsWidth
	}

	var containerWidth: CGFloat {
		boundsWidth - contentInsets.horizontal
	}

}

struct MsgsScrollViewLayout: Layout, Equatable {
	#if DEBUG
		var debugEnabled = LayoutConstants.cacheDebugEnabled
		private func log(_ message: String) {
			if debugEnabled {
				print("[MsgLayout] \(message)")
			}
		}
	#endif

	static func == (lhs: MsgsScrollViewLayout, rhs: MsgsScrollViewLayout) -> Bool {
		lhs.config.boundsWidth == rhs.config.boundsWidth && lhs.config.spacing == rhs.config.spacing
			&& lhs.config.contentInsets == rhs.config.contentInsets
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

// MARK: - Layout Protocol Implementation
extension MsgsScrollViewLayout {
	func makeCache(subviews: Subviews) -> Cache {
		#if DEBUG
			log("makeCache for \(subviews.count) subviews")
		#endif
		return calculateCache(for: subviews, proposedWidth: config.containerWidth)
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

		#if DEBUG
			log(
				"sizeThatFits - cache height: \(cache.totalHeight), proposed: \(proposedSize.height)"
			)
		#endif

		return CGSize(
			width: proposedSize.width,
			height: max(proposedSize.height, cache.totalHeight)
		)
	}

	func explicitAlignment(
		of guide: HorizontalAlignment,
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) -> CGFloat? {
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

	func placeSubviews(
		in bounds: CGRect,
		proposal: ProposedViewSize,
		subviews: Subviews,
		cache: inout Cache
	) {
		#if DEBUG
			log("placeSubviews - placing \(subviews.count) subviews")
		#endif

		guard cache.layouts.count == subviews.count else {
			#if DEBUG
				log("Error: Layout count mismatch (\(cache.layouts.count) != \(subviews.count))")
			#endif
			return
		}

		for (index, subview) in subviews.enumerated() {
			let layout = cache.layouts[index]
			let value = subview[MsgLayoutValueKey.self]
			#if DEBUG
				if debugEnabled {
					log(
						"Placing subview \(index) at \(layout.position), size: \(layout.size), anchor: \(value.anchor)"
					)
				}
			#endif

			subview.place(
				at: layout.position,
				anchor: value.anchor,
				proposal: ProposedViewSize(layout.size)
			)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		#if DEBUG
			log("updateCache called")
		#endif
		cache = calculateCache(for: subviews, proposedWidth: config.containerWidth)
	}
}

// MARK: - Cache Calculation
extension MsgsScrollViewLayout {
	private func calculateCache(for subviews: Subviews, proposedWidth: CGFloat) -> Cache {
		let signatureHash = makeLayoutSignature(subviews: subviews, proposedWidth: proposedWidth)

		#if DEBUG
			log("Calculating cache for \(subviews.count) subviews, signature: \(signatureHash)")
		#endif

		// Try to get valid cached layout
		if let cachedLayout = getValidCachedLayout(
			for: subviews.count,
			boundsWidth: config.boundsWidth,
			signatureHash: signatureHash
		) {
			#if DEBUG
				log("Using cached layout")
			#endif
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

		#if DEBUG
			log("Calculated new cache - height: \(totalHeight), layouts: \(layouts.count)")
		#endif

		return newCache
	}

	private func getValidCachedLayout(
		for subviewsCount: Int,
		boundsWidth: CGFloat,
		signatureHash: Int
	) -> Cache? {
		guard
			let cachedLayout = layoutCache.cache(
				for: subviewsCount,
				boundsWidth: boundsWidth,
				signatureHash: signatureHash
			)
		else {
			return nil
		}

		#if DEBUG
			if debugEnabled {
				log(
					"Cache validation - count: \(subviewsCount) == \(cachedLayout.layouts.count), sig: \(signatureHash) == \(cachedLayout.signatureHash)"
				)
			}
		#endif

		return cachedLayout
	}

	private func calculateCellLayouts(
		for subviews: Subviews,
		proposedWidth: CGFloat
	) -> ([Cache.CellLayout], CGFloat) {
		var layouts: [Cache.CellLayout] = []
		layouts.reserveCapacity(subviews.count)

		var currentY = config.contentInsets.top

		for (index, subview) in subviews.enumerated() {
			let value = subview[MsgLayoutValueKey.self]

			#if DEBUG
				if debugEnabled {
					log(
						"Calculating layout for subview \(index) - uid: \(value.uid), attachments: \(value.attachmentsCount)"
					)
				}
			#endif

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

			#if DEBUG
				if debugEnabled {
					log("  Size: \(size), Position: \(position), Next Y: \(currentY)")
				}
			#endif
		}

		let totalHeight = calculateTotalHeight(sizes: layouts.map(\.size))
		return (layouts, totalHeight)
	}
}

// MARK: - Size Calculation & Caching
extension MsgsScrollViewLayout {
	private func getOrCalculateSize(
		for layoutValue: MsgLayoutValue,
		subview: LayoutSubview,
		proposedWidth: CGFloat
	) -> CGSize {
		let cacheKey = makeSizeCacheKey(
			layoutValue: layoutValue,
			proposedWidth: proposedWidth
		)

		#if DEBUG
			if debugEnabled {
				log("  Size cache key: \(cacheKey)")
			}
		#endif

		if let cachedSize = layoutCache.size(for: cacheKey) {
			#if DEBUG
				if debugEnabled {
					log("  Using cached size: \(cachedSize)")
				}
			#endif
			return cachedSize
		}

		let calculatedSize = calculateOptimalSize(
			for: subview,
			layoutValue: layoutValue,
			proposedWidth: proposedWidth
		)

		#if DEBUG
			if debugEnabled {
				log("  Calculated size: \(calculatedSize)")
			}
		#endif

		layoutCache.setSize(calculatedSize, for: cacheKey)
		return calculatedSize
	}

	private func calculateOptimalSize(
		for subview: LayoutSubview,
		layoutValue: MsgLayoutValue,
		proposedWidth: CGFloat
	) -> CGSize {
		// Determine container width ratio based on attachments
		let containerWidthRatio: CGFloat = {
			switch layoutValue.attachmentsCount {
			case 0:
				return 1.0
			case 1:
				return 0.7
			default:
				return 0.8
			}
		}()

		let containerWidth = proposedWidth * containerWidthRatio
		let targetWidth = containerWidth * LayoutConstants.bubbleWidthRatio

		// Calculate size with height constraint
		let proposedViewSize = ProposedViewSize(
			width: targetWidth,
			height: .infinity
		)

		let dimension = subview.sizeThatFits(proposedViewSize)

		// Cap height to prevent overly large messages
		let finalHeight = min(dimension.height, LayoutConstants.maxBubbleHeight)

		return CGSize(width: dimension.width, height: finalHeight)
	}

	private func makeSizeCacheKey(
		layoutValue: MsgLayoutValue,
		proposedWidth: CGFloat
	) -> String {
		let widthKey = String(format: "%.0f", proposedWidth)
		return
			"\(layoutValue.uid)|\(layoutValue.attachmentsCount)|\(layoutValue.recipient.rawValue)|\(widthKey)|\(Int(config.boundsWidth.rounded()))"
	}
}

// MARK: - Positioning
extension MsgsScrollViewLayout {
	private func calculateXPosition(for recipient: MsgRecipient, bubbleWidth: CGFloat) -> CGFloat {
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
	private func makeLayoutSignature(
		subviews: Subviews,
		proposedWidth: CGFloat
	) -> Int {
		var hasher = Hasher()

		// Combine configuration
		hasher.combine(Int(proposedWidth.rounded()))
		hasher.combine(config.spacing)
		hasher.combine(config.contentInsets.top)
		hasher.combine(config.contentInsets.leading)

		// Combine subview properties
		for subview in subviews {
			let value = subview[MsgLayoutValueKey.self]
			hasher.combine(value.uid)
			hasher.combine(value.recipient.rawValue)
			hasher.combine(value.attachmentsCount)
			// Combine content hash if available
			if let contentHash = value.contentHash {
				hasher.combine(contentHash)
			}
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

// MARK: - Layout Cache
final class MsgsScrollViewLayoutCache: @unchecked Sendable {
	struct CacheKey: Hashable {
		let subviewsCount: Int
		let boundsWidth: CGFloat
		let signatureHash: Int
	}

	private let lock = NSLock()
	private var cacheStore: [CacheKey: MsgsScrollViewLayout.Cache] = [:]
	private var sizeCache: [String: CGSize] = [:]
	private var msgCellLayouts: [String: MsgCellLayout] = [:]

	// For automatic cleanup
	private var cacheTimestamps: [CacheKey: Date] = [:]
	private let cleanupInterval: TimeInterval = 300  // 5 minutes
	private var lastCleanup = Date()

	init() {
		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Initialized")
			}
		#endif
	}

	deinit {
		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Deinitialized")
			}
		#endif
	}

	// MARK: - Size Cache
	func size(for key: String) -> CGSize? {
		lock.lock()
		defer { lock.unlock() }
		maybeCleanupOldEntries()
		return sizeCache[key]
	}

	func setSize(_ size: CGSize?, for key: String) {
		lock.lock()
		defer { lock.unlock() }
		if let size = size {
			sizeCache[key] = size
		} else {
			sizeCache.removeValue(forKey: key)
		}
	}

	// MARK: - Layout Cache
	func cache(
		for subviewsCount: Int,
		boundsWidth: CGFloat,
		signatureHash: Int
	) -> MsgsScrollViewLayout.Cache? {
		lock.lock()
		defer { lock.unlock() }
		maybeCleanupOldEntries()

		let key = CacheKey(
			subviewsCount: subviewsCount,
			boundsWidth: boundsWidth,
			signatureHash: signatureHash
		)

		guard let cached = cacheStore[key] else {
			#if DEBUG
				if LayoutConstants.cacheDebugEnabled {
					print("[MsgLayoutCache] Cache miss for key: \(key)")
				}
			#endif
			return nil
		}

		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Cache hit for key: \(key)")
			}
		#endif
		return cached
	}

	func setCache(
		_ cache: MsgsScrollViewLayout.Cache,
		boundsWidth: CGFloat,
		signatureHash: Int
	) {
		lock.lock()
		defer { lock.unlock() }

		let key = CacheKey(
			subviewsCount: cache.layouts.count,
			boundsWidth: boundsWidth,
			signatureHash: signatureHash
		)

		cacheStore[key] = cache
		cacheTimestamps[key] = Date()

		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Set cache for key: \(key), height: \(cache.totalHeight)")
			}
		#endif
	}

	func layout(for id: String, boundsWidth: CGFloat) -> MsgsScrollViewLayout.Cache.CellLayout? {
		lock.lock()
		defer { lock.unlock() }

		// Find the cache entry for this boundsWidth
		for (key, cache) in cacheStore where key.boundsWidth == boundsWidth {
			if let layout = cache.layouts.first(where: { $0.id == id }) {
				return layout
			}
		}

		return nil
	}

	// MARK: - Message Cell Layout Cache
	func msgCellLayout(for id: String) -> MsgCellLayout? {
		lock.lock()
		defer { lock.unlock() }
		return msgCellLayouts[id]
	}

	func setMsgCellLayout(_ layout: MsgCellLayout?, for id: String) {
		lock.lock()
		defer { lock.unlock() }
		msgCellLayouts[id] = layout
	}

	// MARK: - Cache Management
	func invalidate(_ mode: InvalidationMode = .all) {
		lock.lock()
		defer { lock.unlock() }

		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Invalidating cache: \(mode)")
			}
		#endif

		switch mode {
		case .all:
			cacheStore.removeAll()
			sizeCache.removeAll()
			msgCellLayouts.removeAll()
			cacheTimestamps.removeAll()

		case .sizeOnly:
			sizeCache.removeAll()

		case .layoutOnly:
			cacheStore.removeAll()
			cacheTimestamps.removeAll()

		case .specificId(let id):
			// Remove sizes
			sizeCache = sizeCache.filter { !$0.key.hasPrefix(id + "|") }

			// Remove from layout caches
			for key in cacheStore.keys {
				cacheStore[key]?.layouts.removeAll { $0.id == id }
			}

			// Remove message cell layout
			msgCellLayouts.removeValue(forKey: id)
		}
	}

	func removeCache(for boundsWidth: CGFloat) {
		lock.lock()
		defer { lock.unlock() }

		cacheStore = cacheStore.filter { $0.key.boundsWidth != boundsWidth }
		cacheTimestamps = cacheTimestamps.filter { $0.key.boundsWidth != boundsWidth }

		#if DEBUG
			if LayoutConstants.cacheDebugEnabled {
				print("[MsgLayoutCache] Removed cache for boundsWidth: \(boundsWidth)")
			}
		#endif
	}

	func cleanup(olderThan interval: TimeInterval = 300) {
		lock.lock()
		defer { lock.unlock() }

		let cutoff = Date().addingTimeInterval(-interval)
		let oldKeys = cacheTimestamps.filter { $0.value < cutoff }.keys

		for key in oldKeys {
			cacheStore.removeValue(forKey: key)
			cacheTimestamps.removeValue(forKey: key)
		}

		#if DEBUG
			if LayoutConstants.cacheDebugEnabled && !oldKeys.isEmpty {
				print("[MsgLayoutCache] Cleaned up \(oldKeys.count) old cache entries")
			}
		#endif
	}

	// MARK: - Statistics
	#if DEBUG
		func printStatistics() {
			lock.lock()
			defer { lock.unlock() }

			print("=== MsgLayoutCache Statistics ===")
			print("Layout caches: \(cacheStore.count)")
			print("Size cache entries: \(sizeCache.count)")
			print("Message layouts: \(msgCellLayouts.count)")
			print("Oldest entry: \(cacheTimestamps.values.min()?.description ?? "none")")
			print("================================")
		}
	#endif

	// MARK: - Private Methods
	private func maybeCleanupOldEntries() {
		let now = Date()
		if now.timeIntervalSince(lastCleanup) > cleanupInterval {
			cleanup()
			lastCleanup = now
		}
	}

	// MARK: - Invalidation Mode
	enum InvalidationMode {
		case all
		case sizeOnly
		case layoutOnly
		case specificId(String)
	}
}

// MARK: - Supporting Types
extension MsgRecipient {
	var rawValue: String {
		switch self {
		case .send: return "send"
		case .receive: return "receive"
		case .assistant: return "assistant"
		}
	}
}

// MARK: - Optional Content Hash
extension MsgLayoutValue {
	var contentHash: Int? {
		// Implement based on your actual MsgLayoutValue structure
		// Example: return hash of message content if available
		return nil
	}
}
/*
private enum LayoutConstants {
	static let bubbleWidthRatio: CGFloat = 0.92
	static let singleAttachmentRatio: CGFloat = 0.7
	static let multiAttachmentRatio: CGFloat = 0.8
}

// MARK: - Configuration
struct MsgsScrollViewLayoutConfiguration: Equatable {
	let spacing: CGFloat
	let contentInsets: EdgeInsets
	let boundsSize: CGSize

	// Pre-computed to avoid recalculation
	let containerWidth: CGFloat
	let boundsWidth: CGFloat

	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsSize: CGSize) {
		self.spacing = spacing
		self.contentInsets = contentInsets
		self.boundsSize = boundsSize
		self.containerWidth = boundsSize.width - contentInsets.horizontal
		self.boundsWidth = boundsSize.width
	}

	static func == (lhs: MsgsScrollViewLayoutConfiguration, rhs: MsgsScrollViewLayoutConfiguration) -> Bool {
		lhs.boundsWidth == rhs.boundsWidth &&
		lhs.spacing == rhs.spacing &&
		lhs.contentInsets == rhs.contentInsets
	}
}

// MARK: - Layout Identity for Diffing
private struct LayoutIdentity: Hashable {
	let uid: String
	let recipient: MsgRecipient
	let attachmentsCount: Int

	init(from value: MsgLayoutValue) {
		self.uid = value.uid
		self.recipient = value.recipient
		self.attachmentsCount = value.attachmentsCount
	}
}

// MARK: - Layout
struct MsgsScrollViewLayout: Layout, Equatable {
	private let config: MsgsScrollViewLayoutConfiguration
	private let layoutCache: MsgsScrollViewLayoutCache

	// Track previous state for diffing
	@State private var previousIdentities: [LayoutIdentity] = []

	init(config: MsgsScrollViewLayoutConfiguration, layoutCache: MsgsScrollViewLayoutCache) {
		self.config = config
		self.layoutCache = layoutCache
	}

	static func == (lhs: MsgsScrollViewLayout, rhs: MsgsScrollViewLayout) -> Bool {
		lhs.config == rhs.config
	}
}

// MARK: - Layout Protocol
extension MsgsScrollViewLayout {
	func makeCache(subviews: Subviews) -> Cache {
		calculateCache(for: subviews)
	}

	func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) -> CGSize {
		guard !subviews.isEmpty else {
			return proposal.replacingUnspecifiedDimensions()
		}

		let proposedSize = proposal.replacingUnspecifiedDimensions()
		return CGSize(
			width: proposedSize.width,
			height: max(proposedSize.height, cache.totalHeight)
		)
	}

	func explicitAlignment(of guide: HorizontalAlignment, in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGFloat? {
		guide == .leading ? bounds.minX + config.contentInsets.leading : nil
	}

	func placeSubviews(in _: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout Cache) {
		let layouts = cache.layouts
		guard layouts.count == subviews.count else { return }

		// Optimized: direct indexing instead of zip
		for (index, subview) in subviews.enumerated() {
			let layout = layouts[index]
			let value = subview[MsgLayoutValueKey.self]
			subview.place(
				at: layout.position,
				anchor: value.anchor,
				proposal: .init(layout.size)
			)
		}
	}

	func updateCache(_ cache: inout Cache, subviews: Subviews) {
		cache = calculateCache(for: subviews)
	}
}

// MARK: - Cache Calculation with Diffing
extension MsgsScrollViewLayout {
	private func calculateCache(for subviews: Subviews) -> Cache {
		// Check full layout cache first
		if let cachedLayout = layoutCache.cache(for: subviews.count, boundsWidth: config.boundsWidth) {
			return cachedLayout
		}

		// Build current identities
		let currentIdentities = subviews.map { LayoutIdentity(from: $0[MsgLayoutValueKey.self]) }

		// Diff check: if nothing changed, reuse
		if currentIdentities == previousIdentities,
			let existingCache = layoutCache.cachedLayout[config.boundsWidth] {
			return existingCache
		}

		// Calculate with potential incremental update
		let layouts = calculateLayouts(for: subviews, currentIdentities: currentIdentities)
		let totalHeight = calculateTotalHeight(from: layouts)

		let newCache = Cache(totalHeight: totalHeight, layouts: layouts)
		layoutCache.setCache(newCache, boundsWidth: config.boundsWidth)

		// Store for next diff
		_previousIdentities.wrappedValue = currentIdentities

		return newCache
	}

	private func calculateLayouts(for subviews: Subviews, currentIdentities: [LayoutIdentity]) -> [Cache.CellLayout] {
		var layouts: [Cache.CellLayout] = []
		layouts.reserveCapacity(subviews.count)
		var currentY = config.contentInsets.top

		for (index, subview) in subviews.enumerated() {
			let value = subview[MsgLayoutValueKey.self]
			let identity = currentIdentities[index]

			// Try to reuse size from cache
			let size = getOrCalculateSize(for: value, subview: subview, identity: identity)
			let xPosition = calculateXPosition(for: value.recipient, bubbleWidth: size.width)

			layouts.append(Cache.CellLayout(value.uid, size, CGPoint(x: xPosition, y: currentY)))
			currentY += size.height + config.spacing
		}

		return layouts
	}
}

// MARK: - Size Calculation (Optimized)
extension MsgsScrollViewLayout {
	private func getOrCalculateSize(for layoutValue: MsgLayoutValue, subview: LayoutSubview, identity: LayoutIdentity) -> CGSize {
		let cacheKey = makeSizeCacheKey(identity: identity)

		if let cachedSize = layoutCache.size(for: cacheKey) {
			return cachedSize
		}

		let size = calculateOptimalSize(for: subview, layoutValue: layoutValue)
		layoutCache.setSize(size, for: cacheKey)
		return size
	}

	private func calculateOptimalSize(for subview: LayoutSubview, layoutValue: MsgLayoutValue) -> CGSize {
		let targetWidth = calculateTargetWidth(for: layoutValue)
		let dimension = subview.sizeThatFits(ProposedViewSize(width: targetWidth, height: nil))
		return CGSize(width: dimension.width, height: dimension.height)
	}

	private func calculateTargetWidth(for layoutValue: MsgLayoutValue) -> CGFloat {
		guard layoutValue.attachmentsCount > 0 else {
			return config.containerWidth * LayoutConstants.bubbleWidthRatio
		}

		let ratio = layoutValue.attachmentsCount == 1
		? LayoutConstants.singleAttachmentRatio
		: LayoutConstants.multiAttachmentRatio

		return config.containerWidth * ratio * LayoutConstants.bubbleWidthRatio
	}

	private func makeSizeCacheKey(identity: LayoutIdentity) -> String {
		let roundedWidth = Int(config.containerWidth.rounded())
		let roundedBounds = Int(config.boundsWidth.rounded())
		return "\(identity.uid)|\(identity.attachmentsCount)|\(identity.recipient)|\(roundedWidth)|\(roundedBounds)"
	}
}

// MARK: - Position & Height Calculation
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

	private func calculateTotalHeight(from layouts: [Cache.CellLayout]) -> CGFloat {
		guard !layouts.isEmpty else { return config.contentInsets.vertical }

		let contentHeight = layouts.reduce(0) { $0 + $1.size.height }
		let totalSpacing = config.spacing * CGFloat(layouts.count - 1)
		return config.contentInsets.vertical + contentHeight + totalSpacing
	}
}

// MARK: - Cache Model
extension MsgsScrollViewLayout {
	struct Cache: Hashable, Equatable {
		var totalHeight: CGFloat
		var layouts: [CellLayout]

		struct CellLayout: Equatable, Hashable {
			let id: String
			var size: CGSize
			var position: CGPoint

			init(_ id: String, _ size: CGSize, _ position: CGPoint) {
				self.id = id
				self.size = size
				self.position = position
			}

			var frame: CGRect {
				.init(origin: position, size: size)
			}
		}
	}
}

// MARK: - Cache Manager (Optimized)
final class MsgsScrollViewLayoutCache: @unchecked Sendable {
	private var msgCellLayouts: [String: MsgCellLayout] = [:]
	private var cachedCellSize = [String: CGSize]()
	var cachedLayout = [CGFloat: MsgsScrollViewLayout.Cache]()

	// Thread safety
	private let lock = NSLock()

	init() {}

	deinit {
		msgCellLayouts.removeAll()
		cachedCellSize.removeAll()
		cachedLayout.removeAll()
	}
}

// MARK: - Size Cache
extension MsgsScrollViewLayoutCache {
	func size(for key: String) -> CGSize? {
		lock.lock()
		defer { lock.unlock() }
		return cachedCellSize[key]
	}

	func setSize(_ size: CGSize?, for key: String) {
		lock.lock()
		defer { lock.unlock() }
		cachedCellSize[key] = size
	}

	func clearSizeCache() {
		lock.lock()
		defer { lock.unlock() }
		cachedCellSize.removeAll()
	}
}

// MARK: - Layout Cache
extension MsgsScrollViewLayoutCache {
	func layout(for id: String) -> MsgsScrollViewLayout.Cache.CellLayout? {
		lock.lock()
		defer { lock.unlock() }

		for cache in cachedLayout.values {
			if let layout = cache.layouts.first(where: { $0.id == id }) {
				return layout
			}
		}
		return nil
	}

	func cache(for subviewsCount: Int, boundsWidth: CGFloat) -> MsgsScrollViewLayout.Cache? {
		lock.lock()
		defer { lock.unlock() }

		guard let layout = cachedLayout[boundsWidth] else { return nil }
		guard layout.layouts.count == subviewsCount else { return nil }
		return layout
	}

	func setCache(_ newValue: MsgsScrollViewLayout.Cache, boundsWidth: CGFloat) {
		lock.lock()
		defer { lock.unlock() }
		cachedLayout[boundsWidth] = newValue
	}

	func clearLayoutCache() {
		lock.lock()
		defer { lock.unlock() }
		cachedLayout.removeAll()
	}

	func invalidateCache(for boundsWidth: CGFloat) {
		lock.lock()
		defer { lock.unlock() }
		cachedLayout.removeValue(forKey: boundsWidth)
	}

	func clearAll() {
		lock.lock()
		defer { lock.unlock() }
		cachedCellSize.removeAll()
		cachedLayout.removeAll()
		msgCellLayouts.removeAll()
	}
}

// MARK: - Message Cell Layout
extension MsgsScrollViewLayoutCache {
	func msgCellLayout(for id: String) -> MsgCellLayout? {
		lock.lock()
		defer { lock.unlock() }
		return msgCellLayouts[id]
	}

	func setMsgCellLayout(_ layout: MsgCellLayout?, for id: String) {
		lock.lock()
		defer { lock.unlock() }
		msgCellLayouts[id] = layout
	}
}

// MARK: - Statistics & Debugging
extension MsgsScrollViewLayoutCache {
	func statistics() -> CacheStatistics {
		lock.lock()
		defer { lock.unlock() }

		let totalLayouts = cachedLayout.values.reduce(0) { $0 + $1.layouts.count }
		let estimatedMemory = (totalLayouts * 200) + (cachedCellSize.count * 50) + (msgCellLayouts.count * 100)

		return CacheStatistics(
			layoutCacheCount: cachedLayout.count,
			sizeCacheCount: cachedCellSize.count,
			msgCellLayoutCount: msgCellLayouts.count,
			estimatedMemoryBytes: estimatedMemory
		)
	}
}

struct CacheStatistics {
	let layoutCacheCount: Int
	let sizeCacheCount: Int
	let msgCellLayoutCount: Int
	let estimatedMemoryBytes: Int

	var estimatedMemoryKB: Double {
		Double(estimatedMemoryBytes) / 1024.0
	}
}
*/
//import Database
//import Services
//import SwiftUI
//import XUI
//
//private enum LayoutConstants {
//	static let bubbleWidthRatio: CGFloat = 0.92
//}
//
//struct MsgsScrollViewLayoutConfiguration {
//	let spacing: CGFloat
//	let contentInsets: EdgeInsets
//	private let boundsSize: CGSize
//
//	init(_ spacing: CGFloat, _ contentInsets: EdgeInsets, boundsSize: CGSize) {
//		self.spacing = spacing
//		self.contentInsets = contentInsets
//		self.boundsSize = boundsSize
//	}
//
//	var containerWidth: CGFloat {
//		boundsSize.width - contentInsets.horizontal
//	}
//
//	var boundsWidth: CGFloat {
//		boundsSize.width
//	}
//}
//
//struct MsgsScrollViewLayout: Layout, Equatable {
//	static func == (lhs: MsgsScrollViewLayout, rhs: MsgsScrollViewLayout) -> Bool {
//		lhs.config.boundsWidth == rhs.config.boundsWidth
//	}
//
//	private let config: MsgsScrollViewLayoutConfiguration
//	private let layoutCache: MsgsScrollViewLayoutCache
//
//	init(config: MsgsScrollViewLayoutConfiguration,
//	     layoutCache: MsgsScrollViewLayoutCache)
//	{
//		self.config = config
//		self.layoutCache = layoutCache
//	}
//}
//
//extension MsgsScrollViewLayout {
//	func makeCache(subviews: Subviews) -> Cache {
//		calculateCache(for: subviews, proposedWidth: config.containerWidth)
//	}
//
//	func sizeThatFits(proposal: ProposedViewSize,
//	                  subviews: Subviews,
//	                  cache: inout Cache) -> CGSize
//	{
//		let proposedSize = proposal.replacingUnspecifiedDimensions()
//		guard subviews.isEmpty == false else {
//			return proposedSize
//		}
//		return CGSize(
//			width: proposedSize.width,
//			height: max(proposedSize.height, cache.totalHeight)
//		)
//	}
//
//	func explicitAlignment(of guide: HorizontalAlignment,
//	                       in bounds: CGRect,
//	                       proposal: ProposedViewSize,
//	                       subviews: Subviews,
//	                       cache: inout ()) -> CGFloat?
//	{
//		if guide == .leading {
//			return bounds.minX + config.contentInsets.leading
//		}
//		return nil
//	}
//
//	func placeSubviews(in _: CGRect,
//	                   proposal: ProposedViewSize,
//	                   subviews: Subviews,
//	                   cache: inout Cache)
//	{
//		let layouts = cache.layouts
//		guard layouts.count == subviews.count else {
//			return
//		}
//		let zipped = zip(subviews, layouts)
//		for (subview, layout) in zipped {
//			let value = subview[MsgLayoutValueKey.self]
//			subview.place(
//				at: layout.position,
//				anchor: value.anchor,
//				proposal: .init(layout.size)
//			)
//		}
//	}
//
//	func updateCache(_ cache: inout Cache, subviews: Subviews) {
//		cache = calculateCache(for: subviews, proposedWidth: config.containerWidth)
//	}
//}
//
//extension MsgsScrollViewLayout {
//	private func calculateCache(for subviews: Subviews, proposedWidth: CGFloat) -> Cache {
//		let layoutSignature = makeLayoutSignature(subviews: subviews, proposedWidth: proposedWidth)
//		if let cachedLayout = getValidCachedLayout(
//			for: subviews,
//			boundsWidth: config.boundsWidth
//		) {
//			return cachedLayout
//		}
//
//		let (layouts, totalHeight) = calculateCellLayouts(
//			for: subviews,
//			proposedWidth: proposedWidth,
//			boundsWidth: config.boundsWidth
//		)
//
//		let newCache = Cache(
//			totalHeight: totalHeight,
//			layouts: layouts
//		)
//		layoutCache.setCache(newCache, boundsWidth: config.boundsWidth)
//		return newCache
//	}
//
//	private func getValidCachedLayout(for subviews: Subviews,
//	                                  boundsWidth: CGFloat) -> Cache?
//	{
//		guard let cachedLayout = layoutCache.cache(
//			for: subviews.count,
//			boundsWidth: boundsWidth
//		) else {
//			return nil
//		}
//		return cachedLayout
//	}
//
//	private func calculateCellLayouts(for subviews: Subviews,
//	                                  proposedWidth: CGFloat,
//	                                  boundsWidth: CGFloat) -> ([Cache.CellLayout], CGFloat)
//	{
//		var layouts: [Cache.CellLayout] = []
//		layouts.reserveCapacity(subviews.count)
//
//		var currentY = config.contentInsets.top
//		for subview in subviews {
//			let value = subview[MsgLayoutValueKey.self]
//			let size = getOrCalculateSize(
//				for: value,
//				subview: subview,
//				proposedWidth: proposedWidth,
//				boundsWidth: boundsWidth
//			)
//
//			let xPosition = calculateXPosition(for: value.recipient, bubbleWidth: size.width)
//			let position = CGPoint(x: xPosition, y: currentY)
//			let layout = Cache.CellLayout(value.uid, size, position)
//
//			layouts.append(layout)
//			currentY += size.height + config.spacing
//		}
//		let totalHeight = calculateTotalHeight(sizes: layouts.map(\.size))
//		return (layouts, totalHeight)
//	}
//}
//
//extension MsgsScrollViewLayout {
//	private func getOrCalculateSize(for layoutValue: MsgLayoutValue,
//	                                subview: LayoutSubview,
//	                                proposedWidth: CGFloat,
//	                                boundsWidth: CGFloat) -> CGSize
//	{
//		let cacheKey = makeSizeCacheKey(
//			layoutValue: layoutValue,
//			proposedWidth: proposedWidth,
//			boundsWidth: boundsWidth
//		)
//		if let cachedSize = layoutCache.size(for: cacheKey) {
//			return cachedSize
//		}
//		let calculatedSize = calculateOptimalSize(
//			for: subview,
//			layoutValue: layoutValue,
//			proposedWidth: proposedWidth
//		)
//		layoutCache.setSize(calculatedSize, for: cacheKey)
//		return calculatedSize
//	}
//
//	private func calculateOptimalSize(for subview: LayoutSubview,
//	                                  layoutValue: MsgLayoutValue,
//	                                  proposedWidth: CGFloat) -> CGSize
//	{
//		let containerWidth: CGFloat = {
//			if layoutValue.attachmentsCount == 0 {
//				return proposedWidth
//			}
//			return proposedWidth * (layoutValue.attachmentsCount == 1 ? 0.7 : 0.8)
//		}()
//		let targetWidth = containerWidth * LayoutConstants.bubbleWidthRatio
//		let proposedViewSize = ProposedViewSize(width: targetWidth, height: nil)
//		let dimension = subview.sizeThatFits(proposedViewSize)
//		return .init(width: dimension.width, height: dimension.height)
//	}
//
//	private func makeSizeCacheKey(layoutValue: MsgLayoutValue,
//	                              proposedWidth: CGFloat,
//	                              boundsWidth: CGFloat) -> String
//	{
//		let widthKey = String(format: "%.0f", proposedWidth)
//		return "\(layoutValue.uid)|\(layoutValue.attachmentsCount)|\(layoutValue.recipient)|\(widthKey)|\(Int(boundsWidth.rounded()))"
//	}
//}
//
//extension MsgsScrollViewLayout {
//	private func calculateXPosition(for recipient: MsgRecipient, bubbleWidth: CGFloat) -> CGFloat {
//		switch recipient {
//		case .send:
//			config.boundsWidth - config.contentInsets.trailing
//		case .receive:
//			config.contentInsets.leading
//		case .assistant:
//			config.boundsWidth / 2
//		}
//	}
//}
//
//extension MsgsScrollViewLayout {
//	private func calculateTotalHeight(sizes: [CGSize]) -> CGFloat {
//		let contentHeight = sizes.reduce(0) { $0 + $1.height }
//		let totalSpacing = config.spacing * CGFloat(max(0, sizes.count - 1))
//		return config.contentInsets.vertical + contentHeight + totalSpacing
//	}
//}
//
//extension MsgsScrollViewLayout {
//	private func makeLayoutSignature(subviews: Subviews,
//	                                 proposedWidth: CGFloat) -> Int
//	{
//		var hasher = Hasher()
//		hasher.combine(Int(proposedWidth.rounded()))
//		for subview in subviews {
//			let value = subview[MsgLayoutValueKey.self]
//			hasher.combine(value.uid)
//			hasher.combine(value.recipient)
//			hasher.combine(value.attachmentsCount)
//		}
//		return hasher.finalize()
//	}
//}
