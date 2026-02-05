//
//  MsgsScrollViewLayoutCache.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import Database
import Services
import SwiftUI
import XUI

final class MsgsScrollViewLayoutCache: @unchecked Sendable {

	private var msgCellLayouts: [String: MsgCellLayout] = [:]
	private var cachedCellSize = [String: CGSize]()
	var cachedLayout: MsgsScrollViewLayout.Cache?

	init() {}

	deinit {
		msgCellLayouts.removeAll()
		cachedCellSize.removeAll()
		cachedLayout = nil
	}
}

extension MsgsScrollViewLayoutCache {
	func size(for key: String) -> CGSize? {
		cachedCellSize[key]
	}
	func setSize(_ size: CGSize?, for key: String) {
		cachedCellSize[key] = size
	}
}

extension MsgsScrollViewLayoutCache {
	func layout(for id: String) -> MsgsScrollViewLayout.Cache.CellLayout? {
		cachedLayout?.layouts.last { $0.id == id }
	}

	func cache(for subviewsCount: Int) -> MsgsScrollViewLayout.Cache? {
		guard let cachedLayout else { return nil }
		guard subviewsCount == cachedLayout.layouts.count else { return nil }
		return cachedLayout
	}

	func setCache(_ newValue: MsgsScrollViewLayout.Cache) {
		cachedLayout = newValue
	}

	func invalidateSizes() {
		cachedCellSize.removeAll()
	}
	func invalidateLayout() {
		cachedLayout = nil
	}
	func removeCache(for id: String) {
		cachedCellSize = cachedCellSize.filter { !$0.key.hasPrefix(id + "|") && $0.key != id }
		if let index = cachedLayout?.layouts.firstIndex(where: { $0.id == id }) {
			cachedLayout?.layouts.remove(at: index)
		}
	}
}

extension MsgsScrollViewLayoutCache {
	func msgCellLayout(for id: String) -> MsgCellLayout? {
		msgCellLayouts[id]
	}

	func setMsgCellLayout(_ layout: MsgCellLayout?, for id: String) {
		msgCellLayouts[id] = layout
	}
}
