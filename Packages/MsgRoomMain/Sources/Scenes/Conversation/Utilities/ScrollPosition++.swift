//
//  ScrollPosition++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 19/10/25.
//

import SwiftUI

extension ScrollPosition {
	public static let userDefined = {
		var position = ScrollPosition()
		position.isPositionedByUser = true
		return position
	}()

	public mutating func reset() {
		self = .init()
	}
}
