//
//  ConversationTheme.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 31/10/25.
//

import Database
import SwiftUI
import XUI

public struct ConversationTheme: Sendable, Hashable {
	let backgroundColor: Color
	let outgoingBubbleColor: Color
	let incomingBubbbleColor: Color
	let bubbleCornorRadius: CGFloat
	let shadowColor: Color
	let incomingForegroundColor: Color
	let outgoingForegroundColor: Color

	public init(_ conversation: any ConversationRepresentable) {
		let theme = conversation.theme
		backgroundColor = theme.background.color
		outgoingBubbleColor = theme.outgoingBubbleColor
		incomingBubbbleColor = theme.incomingBubbleColor
		bubbleCornorRadius = theme.bubbleCornorRadius
		shadowColor = Color.opaqueSeparator
		incomingForegroundColor = Color.primary
		outgoingForegroundColor = Color.black
	}

	public static let empty = ConversationTheme(AnyConversation(.system(AI.contact)))

	// MARK: - Hashable

	public static func == (lhs: ConversationTheme, rhs: ConversationTheme) -> Bool {
		lhs.backgroundColor.description == rhs.backgroundColor.description
			&& lhs.outgoingBubbleColor.description == rhs.outgoingBubbleColor.description
			&& lhs.incomingBubbbleColor.description == rhs.incomingBubbbleColor.description && lhs.bubbleCornorRadius == rhs.bubbleCornorRadius
			&& lhs.shadowColor.description == rhs.shadowColor.description
			&& lhs.incomingForegroundColor.description == rhs.incomingForegroundColor.description
			&& lhs.outgoingForegroundColor.description == rhs.outgoingForegroundColor.description
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(backgroundColor.description)
		hasher.combine(outgoingBubbleColor.description)
		hasher.combine(incomingBubbbleColor.description)
		hasher.combine(bubbleCornorRadius)
		hasher.combine(shadowColor.description)
		hasher.combine(incomingForegroundColor.description)
		hasher.combine(outgoingForegroundColor.description)
	}
}
