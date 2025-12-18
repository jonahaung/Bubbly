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

private struct SelectedMsgKey: EnvironmentKey {
	static let defaultValue: SelectedMsg? = nil
}

extension EnvironmentValues {
	var selectedMsg: SelectedMsg? {
		get { self[SelectedMsgKey.self] }
		set { self[SelectedMsgKey.self] = newValue }
	}
}
