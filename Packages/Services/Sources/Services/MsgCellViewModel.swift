//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

@Observable
public final class MsgCellViewModel: Identifiable {

	// MARK: Lifecycle

	public init(_ msg: Message) {
		state = .init(msg: msg)
	}

	// MARK: Public

	public var state: State

	public var msg: Message {
		state.msg
	}

	public func update(with msg: Message) {
		guard state.msg != msg else {
			return
		}
		state.msg = msg
	}

	@MainActor
	public func update(layout: MsgCellLayout) {
		guard state.layout != layout else {
			return
		}
		var state = state
		if layout.showAvatar, state.sender == nil {
			state.sender = ContactsRepository.shared.contact(for: state.senderID)
		}
		state.layout = layout
		state.bubbleCornor = state.computeBubbleCorner()
		self.state = state
	}

	public func setVisibility(_ isVisible: Bool) {
		guard state.isVisible != isVisible else {
			return
		}
		state.isVisible = isVisible
	}

	public func update(selectedMsg: SelectedMsg?) {
		guard state.selectedMsg != selectedMsg else {
			return
		}
		state.selectedMsg = selectedMsg
		state.bubbleCornor = state.computeBubbleCorner()
	}
}

public extension MsgCellViewModel {
	struct State: Equatable, Identifiable {

		// MARK: Lifecycle

		public init(msg: Message) {
			self.msg = msg
			text = {
				guard let text = msg.text else {
					return nil
				}
				return text.containsMarkdown ? MarkdownFormatter().format(text) : .init(text)
			}()
			isSender = msg.isSender
		}

		// MARK: Public

		public var msg: Message
		public let text: AttributedString?
		public let isSender: Bool
		public var sender: Contact? = nil
		public var layout: MsgCellLayout = .init()
		public var isVisible: Bool = false
		public var selectedMsg: SelectedMsg? = nil
		public var bubbleCornor: BubbleCorner = .none

		public var id: String {
			msg.uid
		}

		public var senderID: String {
			msg.senderID
		}

		public var attachments: [Attachment] {
			msg.attachments
		}

		public var reactions: [Reaction] {
			msg.reactions
		}

		public var date: Date {
			msg.date
		}

		public var verticalAlignment: VerticalItemAlignment {
			isSender ? .trailing : .leading
		}

		public var horizontalAlignment: HorizontalAlignment {
			isSender ? .trailing : .leading
		}

		public var foregroundStyle: Color {
			isSender ? .black : .primary
		}

		public var isSelected: Bool {
			selectedMsg?.id == id
		}

		internal func computeBubbleCorner() -> BubbleCorner {
			if selectedMsg?.id == id {
				return .all
			}
			var corner = layout.bubbleCorner
			if selectedMsg?.previous == id {
				corner.append(.bottom)
			}
			if selectedMsg?.next == id {
				corner.append(.top)
			}
			return corner
		}

	}

	var id: String {
		state.id
	}
}

public extension HorizontalAlignment {
	var inverted: HorizontalAlignment {
		self == .leading ? .trailing : .leading
	}
}

public enum VerticalItemAlignment: Sendable, Hashable {
	case leading
	case trailing
}
