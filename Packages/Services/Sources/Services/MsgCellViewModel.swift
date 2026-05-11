// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

@MainActor
@Observable
public final class MsgCellViewModel: @MainActor Identifiable, @MainActor Equatable {
    public var state: State
    public var isVisible: Bool = false

    public init(_ state: State) {
        self.state = state
    }
    public var msg: Message {
        state.msg
    }

    public func update(with msg: Message) {
        guard state.msg != msg else {
            return
        }
        var state = state
        state.msg = msg
        if state.layout.showAvatar {
            state.sender = ContactsRepository.shared.contact(for: state.senderID)
        }
        state.bubbleCornor = state.computeBubbleCorner()
        state.dateStString = nil
        state.computeDateString()
        self.state = state
    }

    public func update(layout: MsgCellLayout) {
        guard state.layout != layout else {
            return
        }
        var state = state
        if layout.showAvatar, state.sender == nil {
            state.sender = ContactsRepository.shared.contact(
                for: state.senderID
            )
        }
        state.layout = layout
        state.bubbleCornor = state.computeBubbleCorner()
        state.computeDateString()
        self.state = state
        
    }

    public func setVisibility(_ isVisible: Bool) {
        guard self.isVisible != isVisible else {
            return
        }
        self.isVisible = isVisible
        
    }

    public func update(selectedMsg: SelectedMsg?) {
        guard state.selectedMsg != selectedMsg else {
            return
        }
        var state = state
        state.selectedMsg = selectedMsg
        state.bubbleCornor = state.computeBubbleCorner()
        self.state = state
    }

    public static func == (lhs: MsgCellViewModel, rhs: MsgCellViewModel) -> Bool {
        lhs.id == rhs.id
    }

}

extension MsgCellViewModel {
    public struct State: Equatable, Hashable, Identifiable {

        @MainActor
        public init(msg: Message, attributedText: AttributedString?, layout: MsgCellLayout) {
            self.msg = msg
            self.attributedText = attributedText
            self.sender = layout.showAvatar ? ContactsRepository.shared.contact(for: msg.senderID) : nil
            self.layout = layout
            self.bubbleCornor = .none
            self.bubbleCornor = computeBubbleCorner()
            computeDateString()
        }

        // MARK: Public

        public var msg: Message
        public let attributedText: AttributedString?

        public var sender: Contact?
        public var layout: MsgCellLayout
        public var selectedMsg: SelectedMsg?
        public var bubbleCornor: BubbleCorner = .none
        public var dateStString: String?
        
        public var isSender: Bool { msg.isSender }

        public var id: String {
            msg.uid
        }
        public var incomingStatus: DeliveryStatus? { msg.incomingStatus }
        public var outgoingStatus: MsgDeliveryState? { msg.outgoingStatus }
        
        public var senderID: String {
            msg.senderID
        }

        public var attachments: [Attachment]? {
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

        public var isSelected: Bool {
            selectedMsg?.id == id
        }

        func computeBubbleCorner() -> BubbleCorner {
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

        public mutating func computeDateString() {
            guard layout.showTimeSeparator, dateStString == nil else { return }
            dateStString = MsgTimeStringFormatter.string(for: date)
        }
    }

    public var id: String {
        state.id
    }
}

extension HorizontalAlignment {
    public var inverted: HorizontalAlignment {
        self == .leading ? .trailing : .leading
    }
}

// MARK: - VerticalItemAlignment

public enum VerticalItemAlignment: Sendable, Hashable {
    case leading
    case trailing
}
