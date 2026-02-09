//
//  MsgsScrollViewLayout+Cache.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 30/9/25.
//

import Foundation

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
