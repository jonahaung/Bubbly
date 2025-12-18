//
//  Attachment++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/9/25.
//

import Database
import Foundation

public extension Attachment {
    var bestFitHeight: CGFloat {
		bestFitWidth / aspectRatio
    }

    var bestFitWidth: CGFloat {
		aspectRatio < 0.9 ? 200 : aspectRatio > 1.1 ? 300 : 150
    }

    var bestFitSize: CGSize {
        .init(width: bestFitWidth, height: bestFitHeight)
    }
}

public extension CGSize {
	func divided(by ratio: CGFloat) -> CGSize {
		.init(width: width / ratio, height: height / ratio)
	}
}
