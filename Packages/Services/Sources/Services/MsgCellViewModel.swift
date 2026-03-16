//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import SwiftUI
import XUI

@Observable
public final class MsgCellViewModel: Identifiable {

	public static func == (lhs: MsgCellViewModel, rhs: MsgCellViewModel) -> Bool {
		lhs.msg == rhs.msg && lhs.state == rhs.state
	}

	public var msg: Message
	public var state: State

    public init(_ msg: Message) {
        state = .init(msg: msg)
        self.msg = msg
    }

    public func update(with msg: Message) {
        guard self.msg != msg else { return }
        self.msg = msg

    }

	@MainActor
    public func update(layout: MsgCellLayout) {
        guard state.layout != layout else { return }
		var state = self.state
        if layout.showAvatar, state.sender == nil {
            state.sender = ContactsRepository.shared.contact(for: msg.senderID)
        }
        state.layout = layout
		self.state = state

    }

    public func setVisibility(_ isVisible: Bool) {
        guard state.isVisible != isVisible else { return }
        state.isVisible = isVisible
    }

    public func update(selectedMsg: SelectedMsg?) {
        state.selectedMsg = selectedMsg

    }
}

public extension MsgCellViewModel {
	struct State: Equatable, Sendable {
        public let id: String
        public let text: String?
        public let attachments: [Attachment]
        public let isSender: Bool
        public var sender: Contact?
        public var layout: MsgCellLayout
        public var isVisible: Bool
        public var selectedMsg: SelectedMsg?
        public var reactions: [Reaction]?
		public var containsMarkdown: Bool

        public init(msg: Message) {
            id = msg.id
            text = msg.text
            attachments = msg.attachments
            isSender = msg.isSender
            sender = nil
            layout = .init()
            isVisible = false
            reactions = msg.reactions.isEmpty ? nil : msg.reactions
            selectedMsg = nil
			containsMarkdown = msg.text?.containsMarkdown == true
        }

        public func computeBubbleCorner() -> BubbleCorner {
            if selectedMsg?.id == id {
                return .all
            }
            var corner = layout.bubbleCorner
            if selectedMsg?.previous == id { corner.append(.bottom) }
            if selectedMsg?.next == id { corner.append(.top) }
            return corner
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

public enum VerticalItemAlignment: Sendable {
    case leading
    case trailing
}

extension UIFont {
    var chatOpticalOffset: CGFloat {
        let topExtra = ascender - capHeight // space above capital letters
        let bottom = abs(descender)
        return (topExtra * 0.18) - (bottom * 0.06)
    }

    var chatVerticalPadding: CGFloat {
        max(10, lineHeight * 0.34)
    }

    var chatHorizontalPadding: CGFloat {
        max(12, lineHeight * 0.55)
    }
}
