import Core
import Database
import Foundation

public struct BubbleFactory: Sendable {
	private let minutesForChatMsgGrouping: Int

	public init(_ minutesForChatMsgGrouping: Int = Settings.Layout.minutesForChatMsgGrouping) {
		self.minutesForChatMsgGrouping = minutesForChatMsgGrouping
	}

	private func resolveCorner(msg: Message,
	                           isSent: Bool,
	                           previousMsg: Message?,
	                           nextMsg: Message?) -> BubbleCorner
	{
		let canPreviousGroup =
			previousMsg.map {
				shouldGroupWithPrevious(
					msg: msg,
					previousMsg: $0
				)
			} ?? true
		let canNextGroup =
			nextMsg.map {
				shouldGroupWithNext(
					msg: msg,
					nextMsg: $0
				)
			} ?? false
		return resolveCorner(
			isSent: isSent,
			hasPrevious: previousMsg != nil,
			hasNext: nextMsg != nil,
			canGroupWithPrevious: canPreviousGroup,
			canGroupWithNext: canNextGroup
		)
	}

	private func resolveCorner(isSent: Bool,
	                           hasPrevious: Bool,
	                           hasNext: Bool,
	                           canGroupWithPrevious: Bool,
	                           canGroupWithNext: Bool) -> BubbleCorner
	{
		switch (hasPrevious, hasNext) {
		case (true, true):
			if canGroupWithPrevious, canGroupWithNext {
				return isSent ? .sendingCenter : .receivingCenter
			}
			if !canGroupWithPrevious, !canGroupWithNext {
				return .all
			}
			if canGroupWithPrevious, !canGroupWithNext {
				return isSent ? .sendingBottom : .receivingBottom
			}
			return isSent ? .sendingTop : .receivingTop
		case (true, false):
			return canGroupWithPrevious
				? (isSent ? .sendingBottom : .receivingBottom)
				: .all
		case (false, true):
			return canGroupWithNext
				? (isSent ? .sendingTop : .receivingTop)
				: .all
		case (false, false):
			return .all
		}
	}

	// MARK: - Time separator & padding

	public func style(for msg: Message,
	                  previous: Message?,
	                  next: Message?) -> MsgCellLayout
	{
		guard let previous else {
			return .init(
				showTimeSeparator: false,
				showTopPadding: false,
				bubbleCorner: resolveCorner(
					msg: msg,
					isSent: msg.receiptType == .send,
					previousMsg: nil,
					nextMsg: next
				)
			)
		}

		let showTimeSeparator = !isSimilarDateTime(of: msg.date, from: previous)
		let canGroupWithPrevious = shouldGroupWithPrevious(msg: msg, previousMsg: previous)
		let showTopPadding = !showTimeSeparator && !canGroupWithPrevious
		let bubbleCorner = resolveCorner(
			msg: msg,
			isSent: msg.receiptType == .send,
			previousMsg: previous,
			nextMsg: next
		)
		return .init(
			showTimeSeparator: showTimeSeparator,
			showTopPadding: showTopPadding,
			bubbleCorner: bubbleCorner
		)
	}

	// MARK: - Grouping helpers

	private func shouldGroupWithPrevious(msg: Message, previousMsg: Message) -> Bool {
		isEqual(of: msg, to: previousMsg) && isSimilarDateTime(
			of: msg.date,
			from: previousMsg
		) && msg.attachments.isEmpty && previousMsg.attachments.isEmpty
	}

	private func shouldGroupWithNext(msg: Message, nextMsg: Message) -> Bool {
		isEqual(of: msg, to: nextMsg) && isSimilarDateTime(
			of: msg.date,
			from: nextMsg
		) && msg.attachments.isEmpty && nextMsg.attachments.isEmpty
	}

	private func isEqual(of thisMsg: Message, to msg: Message) -> Bool {
		thisMsg.senderID == msg.senderID
	}

	private func isSimilarDateTime(of date: Date, from msg: Message) -> Bool {
		let difference = date.getDifference(from: msg.date, unit: .minute)
		return abs(difference) < minutesForChatMsgGrouping
	}
}
