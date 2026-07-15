// © 2026 Aung Ko Min

import Core
import Database
import Foundation

public struct MsgCellDecorator: Sendable {
    private let minutesForChatMsgGrouping: Int

    public init(_ minutesForChatMsgGrouping: Int = Settings.Layout.minutesForChatMsgGrouping) {
        self.minutesForChatMsgGrouping = minutesForChatMsgGrouping
    }

    private func resolveCorner(
        isSent: Bool,
        canGroupWithPrevious: Bool,
        canGroupWithNext: Bool,
    ) -> BubbleCorner {
        switch (canGroupWithPrevious, canGroupWithNext) {
        case (true, true):
            return isSent ? .sendingCenter : .receivingCenter
        case (true, false):
            return isSent ? .sendingBottom : .receivingBottom
        case (false, true):
            return isSent ? .sendingTop : .receivingTop
        case (false, false):
            return .all
        }
    }

    // MARK: - Time separator & padding

    public func style(
        for msg: Message,
        previous: Message?,
        next: Message?,
    ) -> MsgCellDecoration {
        let cangroupWithPrevious = if let previous { msg.cangroup(with: previous, timeGap: minutesForChatMsgGrouping) } else { false }
        let canGroupWithNext = if let next { msg.cangroup(with: next, timeGap: minutesForChatMsgGrouping) } else { false }
        let bubbleCorner = resolveCorner(isSent: msg.isSender, canGroupWithPrevious: cangroupWithPrevious, canGroupWithNext: canGroupWithNext)
        let showTimeSeparator = if let previous { !msg.isSimilarDateTime(with: previous, timeGap: minutesForChatMsgGrouping)} else { false }
        let showBottomPadding = if let next { !canGroupWithNext && msg.isSimilarDateTime(with: next, timeGap: minutesForChatMsgGrouping) } else { false }
        return .init(showTimeSeparator: showTimeSeparator, showBottomSpacer: showBottomPadding, bubbleCorner: bubbleCorner)
        
    }
    public func bubbleCorner(
        for msg: Message,
        previous: Message?,
        next: Message?,
    ) -> BubbleCorner {
        let cangroupWithPrevious = if let previous { msg.cangroup(with: previous, timeGap: minutesForChatMsgGrouping) } else { false }
        let canGroupWithNext = if let next { msg.cangroup(with: next, timeGap: minutesForChatMsgGrouping) } else { false }
        let bubbleCorner = resolveCorner(isSent: msg.isSender, canGroupWithPrevious: cangroupWithPrevious, canGroupWithNext: canGroupWithNext)
        return bubbleCorner
    }
}

private extension Message {
    func cangroup(with other: Message, timeGap: Int) -> Bool {
        self.senderID == other.senderID && isSimilarDateTime(with: other, timeGap: timeGap)
    }
    func isSimilarDateTime(with msg: Message, timeGap: Int) -> Bool {
        let difference = date.getDifference(from: msg.date, unit: .minute)
        return abs(difference) < timeGap
    }
}
