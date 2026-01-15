//
//  ConversationTheme.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 31/10/25.
//

import Database
import SwiftUI
import XUI

public struct ConversationTheme: Sendable, Hashable, Equatable, EmptyRepresentable {
	// Rendering properties used by views
	let id: String
	let backgroundColor: Color
	let outgoingBubbleColor: Color
	let outgoingShadowColor: Color
	let incomingBubbbleColor: Color
	let incomingShadowColor: Color
	let bubbleCornorRadius: CGFloat
	let incomingForegroundColor: Color
	let outgoingForegroundColor: Color
	let bubblePading: EdgeInsets

	public init(_ conversation: Conversation) {
		let theme = conversation.properties.theme
		self.id = conversation.uid
		// Colors for rendering
		let backgroundColor = theme.background.color
		let outgoingBubbleColor = theme.outgoingBubbleColor
		let incomingBubbbleColor = theme.incomingBubbleColor
		let incomingForegroundColor = Color.darkText
		let outgoingForegroundColor = Color.darkText

		self.backgroundColor = backgroundColor
		self.outgoingBubbleColor = outgoingBubbleColor.exposureAdjust(0.1)
		self.incomingBubbbleColor = (theme.background == .system ? .secondarySystemBackground : incomingBubbbleColor).exposureAdjust(0.1)
		self.bubbleCornorRadius = theme.bubbleCornorRadius
		self.incomingForegroundColor = incomingForegroundColor
		self.outgoingForegroundColor = outgoingForegroundColor
		self.bubblePading = .init(
			top: UIFont.labelFontSize * 0.6,
			leading: UIFont.labelFontSize * 0.7,
			bottom: UIFont.labelFontSize * 0.6,
			trailing: UIFont.labelFontSize * 0.7
		)
		outgoingShadowColor = outgoingBubbleColor.mix(with: .primary, by: 0.1)
		incomingShadowColor = incomingBubbbleColor.mix(with: .primary, by: 0.1)
	}

	public static let empty = ConversationTheme(.empty)

	public static func == (lhs: ConversationTheme, rhs: ConversationTheme) -> Bool {
		lhs.id == rhs.id && lhs.outgoingBubbleColor == rhs.outgoingBubbleColor && lhs.incomingBubbbleColor == rhs.incomingBubbbleColor && lhs.backgroundColor == rhs.backgroundColor
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(id)
	}
}
