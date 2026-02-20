import Core
import Database
import SwiftUI
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
		lhs.uid == rhs.uid && lhs.recipient == rhs.recipient
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
		.init(
			uid: uid,
			recipient: receiptType,
			attachmentsCount: attachments.count
		)
	}
}

extension ContainerValues {
	@Entry var viewIsVisible = false
}
