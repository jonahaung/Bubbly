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
	let id: String
	let backgroundColor: Color
	let outgoingBubbleColor: Color
	let outgoingShadowColor: Color
	let incomingBubbbleColor: Color
	let incomingShadowColor: Color
	let bubbleCornorRadius: CGFloat
	let bubblePading: EdgeInsets
	let fontSize: CGFloat

	public init(_ conversation: Conversation) {
		let theme = conversation.properties.theme
		self.id = conversation.uid
		// Colors for rendering
		let backgroundColor = theme.background.color
		let outgoingBubbleColor = theme.outgoingBubbleColor
		let incomingBubbbleColor = theme.incomingBubbleColor

		self.backgroundColor = backgroundColor
		self.outgoingBubbleColor = outgoingBubbleColor
		self.incomingBubbbleColor = (theme.background == .system ? .secondarySystemBackground : incomingBubbbleColor)
		
		let font = UIFont.preferredFont(forTextStyle: .body)
		fontSize = font.pointSize
		let verticalPadding = font.chatVerticalPadding
		let horizontalPadding = font.chatHorizontalPadding
		self.bubblePading = .init(
			top: verticalPadding,
			leading: horizontalPadding,
			bottom: verticalPadding,
			trailing: horizontalPadding
		)
		self.bubbleCornorRadius = max(16, font.lineHeight * 0.75)
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
extension UIFont {
	/// Small vertical tweak to make text feel centered in a pill/bubble (iMessage-ish).
	var chatOpticalOffset: CGFloat {
		let topExtra = ascender - capHeight      // space above capital letters
		let bottom = abs(descender)
		// tuned for SF Pro Text/Display; usually about -1...+1 pt depending on size
		return (topExtra * 0.18) - (bottom * 0.06)
	}

	/// Bubble vertical padding that scales well with SF Pro and Dynamic Type.
	var chatVerticalPadding: CGFloat {
		max(10, lineHeight * 0.34)
	}

	/// Bubble horizontal padding.
	var chatHorizontalPadding: CGFloat {
		max(12, lineHeight * 0.55)
	}
}
