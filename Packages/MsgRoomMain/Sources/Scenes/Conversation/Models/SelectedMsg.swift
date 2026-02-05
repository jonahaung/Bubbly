//
//  SelectedMsg.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 1/10/25.
//

import Database
import SwiftUI

public struct SelectedMsg: Hashable, Identifiable, Sendable {
	public var id: String
	public var previous: String?
	public var next: String?

	public init(id: String, previous: String? = nil, next: String? = nil) {
		self.id = id
		self.previous = previous
		self.next = next
	}
}
extension EnvironmentValues {
	@Entry var selectedMsg: SelectedMsg?
}
