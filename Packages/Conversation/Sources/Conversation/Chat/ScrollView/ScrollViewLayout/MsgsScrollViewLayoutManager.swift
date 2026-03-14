//
//  MsgsScrollViewLayoutManager.swift
//  Conversation
//
//  Created by Aung Ko Min on 9/3/26.
//

import Database
import Services
import SwiftUI

final class MsgsScrollViewLayoutManager: @unchecked Sendable {

	private(set) var selectedMsg: SelectedMsg?
	private(set) var config: MsgsScrollViewLayoutConfiguration
	private var sizeStore = [MsgsScrollViewLayout.SubviewKey: CGSize]()
	private var cacheStore = [MsgsScrollViewLayout.CacheKey: MsgsScrollViewLayout.Cache]()
	private(set) var metrics = LayoutMetrics()

	init(config: MsgsScrollViewLayoutConfiguration) {
		self.config = config
	}
}

extension MsgsScrollViewLayoutManager {
	func size(for key: MsgsScrollViewLayout.SubviewKey) -> CGSize? {
		sizeStore[key]
	}

	func set(size: CGSize, for key: MsgsScrollViewLayout.SubviewKey) {
		sizeStore[key] = size
	}
}
extension MsgsScrollViewLayoutManager {
	func updateSelectedMsg(_ newValue: SelectedMsg?) {
		selectedMsg = newValue
	}

	var boundsWidth: CGFloat {
		config.boundsWidth
	}

	func updateBoundsWidth(_ newValue: CGFloat) {
		config.boundsWidth = newValue
	}

	func cache(for key: MsgsScrollViewLayout.CacheKey) -> MsgsScrollViewLayout.Cache? {
		cacheStore[key]
	}

	func set(cache: MsgsScrollViewLayout.Cache, for key: MsgsScrollViewLayout.CacheKey) {
		cacheStore[key] = cache
	}
}

extension MsgsScrollViewLayoutManager {
	struct LayoutMetrics: Sendable {
		var cacheHit: Int = 0
		var incrementalUpdate: Int = 0
		var fullRebuild: Int = 0
	}

	func trackCacheHit() {
		metrics.cacheHit += 1
	}

	func trackIncrementalUpdate() {
		metrics.incrementalUpdate += 1
	}

	func trackFullRebuild() {
		metrics.fullRebuild += 1
	}
}
