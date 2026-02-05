//
//  BubbleFactory.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Core
import Database
import UIKit

public struct BubbleFactory: Sendable {
    private let minutesForChatMsgGrouping: Int

    public init(
        _ minutesForChatMsgGrouping: Int = Settings.Layout.minutesForChatMsgGrouping
    ) {
        self.minutesForChatMsgGrouping = minutesForChatMsgGrouping
    }

    private func getBubble(
        msg: Message,
        previousMsg: Message?,
        nextMsg: Message?
    ) -> Bubble {
        var bubble = Bubble()
        bubble.bubbleCorner = resolveCorner(
            msg: msg,
            isSent: msg.receiptType == .send,
            previousMsg: previousMsg,
            nextMsg: nextMsg
        )
        return bubble
    }

    // MARK: - Corner resolution

    private func resolveCorner(
        msg: Message,
        isSent: Bool,
        previousMsg: Message?,
        nextMsg: Message?
    ) -> BubbleCorner {
        if isSent {
            resolveSendingCorner(msg, previousMsg: previousMsg, nextMsg: nextMsg)
        } else {
            resolveReceivingCorner(msg, previousMsg: previousMsg, nextMsg: nextMsg)
        }
    }

    private func resolveSendingCorner(
        _ msg: Message,
        previousMsg: Message?,
        nextMsg: Message?
    ) -> BubbleCorner {
        let canPreviousGroup =
            previousMsg.map {
                shouldGroupWithPrevious(
                    msg: msg,
                    previousMsg: $0
                )
            } ?? false
        let canNextGroup =
            nextMsg.map {
                shouldGroupWithNext(
                    msg: msg,
                    nextMsg: $0
                )
            } ?? false

        switch (previousMsg != nil, nextMsg != nil) {
        case (true, true):
            if canPreviousGroup, canNextGroup { return .sendingCenter }
            if !canPreviousGroup, !canNextGroup { return .all }
            if canPreviousGroup, !canNextGroup { return .sendingBottom }
            return .sendingTop
        case (true, false):
            return canPreviousGroup ? .sendingBottom : .all
        case (false, true):
            return canNextGroup ? .sendingTop : .all
        case (false, false):
            return .all
        }
    }

    private func resolveReceivingCorner(
        _ msg: Message,
        previousMsg: Message?,
        nextMsg: Message?
    ) -> BubbleCorner {
        let canPreviousGroup =
            previousMsg.map {
                shouldGroupWithPrevious(
                    msg: msg,
                    previousMsg: $0
                )
            } ?? false
        let canNextGroup =
            nextMsg.map {
                shouldGroupWithNext(
                    msg: msg,
                    nextMsg: $0
                )
            } ?? false

        switch (previousMsg != nil, nextMsg != nil) {
        case (true, true):
            if canPreviousGroup, canNextGroup { return .receivingCenter }
            if !canPreviousGroup, !canNextGroup { return .all }
            if canPreviousGroup, !canNextGroup { return .receivingBottom }
            return .receivingTop
        case (true, false):
            return canPreviousGroup ? .receivingBottom : .all
        case (false, true):
            return canNextGroup ? .receivingTop : .all
        case (false, false):
            return .all
        }
    }

    // MARK: - Time separator & padding

    public func style(
        for msg: Message,
        previous: Message?,
        next: Message?
    ) -> MsgCellLayout {
        guard let previous else {
            return .init(
                showTimeSeparator: false,
                showTopPadding: false,
                bubble: getBubble(msg: msg, previousMsg: nil, nextMsg: next)
            )
        }

        let showTimeSeparater = !isSimilierDateTime(of: msg.date, from: previous)
		let showTopPadding = !showTimeSeparater && (
			msg.senderID != previous.senderID || msg.attachments
				.isEmpty == false)
        let bubble = getBubble(msg: msg, previousMsg: previous, nextMsg: next)
        return .init(
            showTimeSeparator: showTimeSeparater,
            showTopPadding: showTopPadding,
            bubble: bubble
        )
    }

    // MARK: - Grouping helpers

    private func shouldGroupWithPrevious(msg: Message, previousMsg: Message) -> Bool {
		isEqual(of: msg, to: previousMsg) && isSimilierDateTime(
			of: msg.date,
			from: previousMsg
		) && previousMsg.attachments.isEmpty
    }

    private func shouldGroupWithNext(msg: Message, nextMsg: Message) -> Bool {
		isEqual(of: msg, to: nextMsg) && isSimilierDateTime(
			of: msg.date,
			from: nextMsg
		) && nextMsg.attachments.isEmpty
    }

    private func isEqual(of thisMsg: Message, to msg: Message) -> Bool {
        thisMsg.senderID == msg.senderID
    }

    private func isSimilierDateTime(of date: Date, from msg: Message) -> Bool {
        let difference = date.getDifference(from: msg.date, unit: .minute)
        return abs(difference) < minutesForChatMsgGrouping
    }
}
