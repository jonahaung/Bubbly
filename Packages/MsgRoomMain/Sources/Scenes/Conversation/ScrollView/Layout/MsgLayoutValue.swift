//
//  MsgLayoutValue.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 3/9/25.
//

import Database
import SwiftUI
import Core
import XUI

struct MsgLayoutValue: Sendable, Hashable, Equatable, UIdentifiable {

	let uid: String
	let recipient: MsgRecipient
	let attachmentsCount: Int

	var anchor: UnitPoint {
		switch recipient {
		case .send:
				.topTrailing
		case .receive:
				.topLeading
		case .assistant:
				.top
		}
	}

	static func == (lhs: MsgLayoutValue, rhs: MsgLayoutValue) -> Bool {
		return lhs.uid == rhs.uid
	}

	static let empty = MsgLayoutValue(
		uid: String(),
		recipient: .assistant,
		attachmentsCount: 0
	)
}

struct MsgLayoutValueKey: LayoutValueKey {
	static let defaultValue: MsgLayoutValue = .empty
}
extension Message {
	func layoutValue() -> MsgLayoutValue {
		return .init(
			uid: uid,
			recipient: receiptType,
			attachmentsCount: attachments.count
		)
	}
}
extension ContainerValues {
	@Entry var viewIsVisible = false
}
