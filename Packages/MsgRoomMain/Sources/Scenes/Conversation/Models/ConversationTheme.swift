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
	struct Theme {
		let bubbleCoor: Color
		let shadowColor: Color
		let foregroundStyle: Color
	}

	let theme: Database.ConversationTheme
	let outgoing: Theme
	let incoming: Theme
	let backgroundColor: Color
	let bubbleCornerRadius: CGFloat
	let bubblePading: EdgeInsets
	let font: Font

	public init(_ conversation: Conversation) {
		let theme = conversation.properties.theme
		backgroundColor = theme.background.color

		outgoing = .init(
			bubbleCoor: theme.outgoingBubbleColor,
			shadowColor: theme.outgoingBubbleColor.mix(with: .primary, by: 0.1),
			foregroundStyle: .darkText
		)
		incoming = .init(
			bubbleCoor: theme.incomingBubbleColor,
			shadowColor: theme.incomingBubbleColor.mix(with: .primary, by: 0.1),
			foregroundStyle: .primary
		)
		let uiFont = UIFont.preferredFont(forTextStyle: .body)
		font = .system(size: uiFont.pointSize)
		let verticalPadding = uiFont.chatVerticalPadding
		let horizontalPadding = uiFont.chatHorizontalPadding
		bubblePading = .init(
			top: verticalPadding,
			leading: horizontalPadding,
			bottom: verticalPadding,
			trailing: horizontalPadding
		)
		bubbleCornerRadius = max(16, uiFont.lineHeight * 0.75)
		self.theme = conversation.theme
	}

	public static let empty = ConversationTheme(.empty)

	public static func == (lhs: ConversationTheme, rhs: ConversationTheme) -> Bool {
		lhs.theme == rhs.theme
	}

	public func hash(into hasher: inout Hasher) {
		hasher.combine(theme)
	}

	public func bubbleColor(for isSender: Bool) -> some ShapeStyle {
		isSender ? outgoing.bubbleCoor : incoming.bubbleCoor
	}

	public func foregroundStyle(for isSender: Bool) -> some ShapeStyle {
		isSender ? outgoing.foregroundStyle : incoming.foregroundStyle
	}

	public func shadowColor(for isSender: Bool) -> some ShapeStyle {
		isSender ? outgoing.shadowColor : incoming.shadowColor
	}
}

extension UIFont {
	var chatOpticalOffset: CGFloat {
		let topExtra = ascender - capHeight // space above capital letters
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
