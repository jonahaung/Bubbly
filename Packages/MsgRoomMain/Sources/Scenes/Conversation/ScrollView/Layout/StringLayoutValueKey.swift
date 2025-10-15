//
//  StringLayoutValueKey.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import SwiftUI
import Database

struct MsgLayoutValue: Hashable {
	let uid: String
	let recipient: MsgRecipient
	init(uid: String, recipient: MsgRecipient) {
		self.uid = uid
		self.recipient = recipient
	}
}
struct MsgLayoutValueKey: LayoutValueKey {
	static let defaultValue: MsgLayoutValue = .init(uid: "", recipient: .none)
}
extension View {
	func layoutValue(_ value: MsgLayoutValue) -> some View {
		layoutValue(key: MsgLayoutValueKey.self, value: value)
	}
}
extension MsgSnapshot {
	var layoutValue: MsgLayoutValue {
		.init(uid: uid, recipient: receiptType)
	}
}
