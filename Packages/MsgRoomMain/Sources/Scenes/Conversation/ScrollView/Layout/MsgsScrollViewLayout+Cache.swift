//
//  MsgsScrollViewLayout+Cache.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 30/9/25.
//

import Foundation

extension MsgsScrollViewLayout {
	struct Cache {
		var layouts: [CellLayout]
	}
	struct CellLayout: Identifiable {
		let id: String
		let size: CGSize
		var position: CGPoint

		init(_ id: String, _ size: CGSize, _ position: CGPoint) {
			self.id = id
			self.size = size
			self.position = position
		}
	}
}
