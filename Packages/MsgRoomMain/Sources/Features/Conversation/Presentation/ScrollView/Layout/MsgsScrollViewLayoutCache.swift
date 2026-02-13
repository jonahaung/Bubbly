import Foundation
import Services

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
	private let cleanupInterval: TimeInterval = 300 // 5 minutes
	private var lastCleanup = Date()

	init() {}

	deinit {}

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
		if let size {
			sizeCache[key] = size
		} else {
			sizeCache.removeValue(forKey: key)
		}
	}

	// MARK: - Layout Cache

	func cache(for subviewsCount: Int,
	           boundsWidth: CGFloat,
	           signatureHash: Int) -> MsgsScrollViewLayout.Cache?
	{
		lock.lock()
		defer { lock.unlock() }
		maybeCleanupOldEntries()

		let key = CacheKey(
			subviewsCount: subviewsCount,
			boundsWidth: boundsWidth,
			signatureHash: signatureHash
		)

		guard let cached = cacheStore[key] else {
			return nil
		}
		return cached
	}

	func setCache(_ cache: MsgsScrollViewLayout.Cache,
	              boundsWidth: CGFloat,
	              signatureHash: Int)
	{
		lock.lock()
		defer { lock.unlock() }

		let key = CacheKey(
			subviewsCount: cache.layouts.count,
			boundsWidth: boundsWidth,
			signatureHash: signatureHash
		)

		cacheStore[key] = cache
		cacheTimestamps[key] = Date()
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

	func invalidate(_ mode: InvalidationMode = .all) {
		lock.lock()
		defer { lock.unlock() }

		switch mode {
		case .all:
			cacheStore.removeAll()
			sizeCache.removeAll()
			cacheTimestamps.removeAll()
		case .sizeOnly:
			sizeCache.removeAll()
		case .layoutOnly:
			cacheStore.removeAll()
			cacheTimestamps.removeAll()
		case let .specificId(id):
			// Remove sizes
			sizeCache = sizeCache.filter { !$0.key.contains(id + "|") }
			for key in cacheStore.keys {
				cacheStore[key]?.layouts.removeAll(where: { $0.id.contains(id + "|") })
			}
		}
	}

	func removeCache(for boundsWidth: CGFloat) {
		lock.lock()
		defer { lock.unlock() }

		cacheStore = cacheStore.filter { $0.key.boundsWidth != boundsWidth }
		cacheTimestamps = cacheTimestamps.filter { $0.key.boundsWidth != boundsWidth }
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
	}

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
