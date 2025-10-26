//
//  LayoutSubViews++.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 17/10/25.
//

import SwiftUI

public extension LayoutSubviews {
	func values<T: LayoutValueKey>(key: T.Type) -> [T.Value] {
		self.map { $0[key] }
	}
}
