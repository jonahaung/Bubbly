// © 2026 Aung Ko Min

import Database
import SwiftUI
import XUI

@Observable
public final class MsgCellViewModel: @preconcurrency Identifiable {
    
    public var state: State
    public var isVisible: Bool = false
    public var layoutValue: MsgLayoutValue

    public init(_ state: State) {
        self.state = state
        layoutValue = .init(
            uid: state.msg.uid,
            recipient: state.msg.receiptType,
            hasAttachment: state.msg.attachments?.isEmpty ?? true == false,
            headerID: state.layout.id,
            isSelected: state.isSelected
        )
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
        state.refreshDerivedState()
        self.state = state
    }

    public func update(layout: MsgCellDecoration) {
        guard state.layout != layout else {
            return
        }
        var state = state
        state.layout = layout
        state.refreshDerivedState()
        layoutValue.headerID = layout.id
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
        state.computeBubbleCorner()
        self.state = state
        layoutValue = .init(
            uid: state.msg.uid,
            recipient: state.msg.receiptType,
            hasAttachment: state.msg.attachments?.isEmpty ?? true == false,
            headerID: state.layout.id,
            isSelected: state.isSelected
        )
    }

    public static func == (lhs: MsgCellViewModel, rhs: MsgCellViewModel) -> Bool
    {
        lhs.id == rhs.id
    }
}

extension MsgCellViewModel {
    public struct State: Sendable, Equatable, Hashable, Identifiable {
        public init(
            msg: Message,
            attributedText: AttributedString?,
            layout: MsgCellDecoration
        ) {
            self.msg = msg
            self.attributedText = attributedText
            self.layout = layout
            self.bubbleCornor = .none
            refreshDerivedState()
        }

        public var msg: Message
        public var attributedText: AttributedString?

        public var layout: MsgCellDecoration
        public var selectedMsg: SelectedMsg?
        public var bubbleCornor: BubbleCorner
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

        public mutating func refreshDerivedState() {
            computeBubbleCorner()
            updateDateString()
        }

        public mutating func computeBubbleCorner() {
            guard let selectedMsg else {
                bubbleCornor = layout.bubbleCorner
                return
            }
            if selectedMsg.id == id {
                bubbleCornor = .all
                return
            }
            var corner = layout.bubbleCorner
            if selectedMsg.previous == id {
                corner.append(.bottom)
            }
            if selectedMsg.next == id {
                corner.append(.top)
            }
            bubbleCornor = corner
        }

        private mutating func updateDateString() {
            if layout.showTimeSeparator {
                if dateStString == nil {
                    dateStString = MsgTimeStringFormatter.string(for: date)
                }
            } else if dateStString != nil {
                dateStString = nil
            }
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
