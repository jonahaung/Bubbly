//
//  MsgsScrollViewLayoutCache.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import SwiftUI
import Database
import Services
import XUI

private enum CacheConstants {
	static let searchRectSize = CGSize(width: 20, height: 20)
}

final class MsgsScrollViewLayoutCache: @unchecked Sendable {

	private var msgCellLayouts: [String: MsgCellLayout] = [:]
	private var cachedLayout = MsgsScrollViewLayout.Cache.empty(boundsWidth: 0, contentInsets: .init())

	init() {}
}

extension MsgsScrollViewLayoutCache {

	func size(for msgID: String) -> CGSize? {
		return cachedLayout.layouts.first(where: { $0.id == msgID })?.size
	}

	func setSize(_ size: CGSize, for msgID: String) {
		if var layout = cachedLayout.layouts.first(where: { $0.id == msgID }) {
			layout.size = size
			cachedLayout.layouts.replace(layout)
		}
	}
}

extension MsgsScrollViewLayoutCache {

	func layout(for location: CGPoint) -> MsgsScrollViewLayout.CellLayout? {
		return cachedLayout.layouts.first { $0.frame.contains(location) }
	}
	func layout(for id: String) -> MsgsScrollViewLayout.CellLayout? {
		return cachedLayout.layouts.last { $0.id == id }
	}

	func cache(for boundsWidth: CGFloat) -> MsgsScrollViewLayout.Cache? {
		let isValid = cachedLayout.boundsWidth == boundsWidth
		guard isValid else {
			invalidateLayout()
			return nil
		}
		return cachedLayout
	}

	func setCache(_ newValue: MsgsScrollViewLayout.Cache) {
		cachedLayout = newValue
	}

	func invalidateLayout() {
		cachedLayout.layouts.removeAll()
		cachedLayout.boundsWidth = 0
		cachedLayout.totalHeight = 0
		msgCellLayouts.removeAll()
	}
}

extension MsgsScrollViewLayoutCache {

	func msgCellLayout(for id: String) -> MsgCellLayout? {
		return msgCellLayouts[id]
	}

	func setMsgCellLayout(_ layout: MsgCellLayout?, for id: String) {
		msgCellLayouts[id] = layout
	}
}

private extension MsgsScrollViewLayoutCache {

	func createSearchRect(around point: CGPoint, size: CGSize) -> CGRect {
		CGRect(
			x: point.x - size.width / 2,
			y: point.y - size.height / 2,
			width: size.width,
			height: size.height
		)
	}
}
