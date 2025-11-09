//
//  MsgLayoutValue.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import Database
import SwiftUI

struct MsgLayoutValue: Hashable {
	let uid: String
	let recipient: MsgRecipient
}

struct MsgLayoutValueKey: LayoutValueKey {
	static let defaultValue: MsgLayoutValue = .init(uid: "", recipient: .none)
}

extension View {
	func layoutValue(_ value: MsgLayoutValue) -> some View {
		layoutValue(key: MsgLayoutValueKey.self, value: value)
	}
}

extension Message {
	var layoutValue: MsgLayoutValue {
		.init(uid: uid, recipient: receiptType)
	}
}
