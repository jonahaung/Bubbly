//
//  Attachment++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import Foundation
import Database

public extension Attachment {
	var bestFitHeight: CGFloat {
		if aspectRatio == 1 {
			return 200
		}
		return min(300, max(150, 200 * 1/aspectRatio))
	}
	var bestFitWidth: CGFloat {
		bestFitHeight * aspectRatio
	}
	var bestFitSize: CGSize {
		.init(width: bestFitWidth, height: bestFitHeight)
	}
}
