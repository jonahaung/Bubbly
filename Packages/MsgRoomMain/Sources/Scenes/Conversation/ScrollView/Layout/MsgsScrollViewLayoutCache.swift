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

final class MsgsScrollViewLayoutCache: @unchecked Sendable {

	private var msgCellLayouts: [String: MsgCellLayout] = [:]
	private var layouts: [String: MsgsScrollViewLayout.CellLayout] = [:]
	
	func layout(for msgID: String, boundsWidth: CGFloat) -> MsgsScrollViewLayout.CellLayout? {
		let layoutID = makeLayoutID(msgID, boundsWidth)
		return layouts[layoutID]
	}
	
	func setLayout(_ layout: MsgsScrollViewLayout.CellLayout, for msgID: String, boundsWidth: CGFloat) {
		let layoutID = makeLayoutID(msgID, boundsWidth)
		layouts[layoutID] = layout
	}
	
	func removeLayout(for msgID: String, boundsWidth: CGFloat) {
		let layoutID = makeLayoutID(msgID, boundsWidth)
		layouts[layoutID] = nil
	}
	
	private func makeLayoutID(_ msgID: String, _ width: CGFloat) -> String {
		"\(msgID)_\(width)"
	}

	func msgCellLayout(for id: String) -> MsgCellLayout? {
		msgCellLayouts[id]
	}

	func setMsgCellLayout(_ layout: MsgCellLayout, for id: String) {
		msgCellLayouts[id] = layout
	}
}
