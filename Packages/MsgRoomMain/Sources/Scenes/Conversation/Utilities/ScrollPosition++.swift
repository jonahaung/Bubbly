//
//  ScrollPosition++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/10/25.
//

import SwiftUI

public extension ScrollPosition {
	static let userDefined = {
		var position = ScrollPosition()
		position.isPositionedByUser = true
		return position
	}()
	mutating func reset() {
		self = .init()
	}
}
