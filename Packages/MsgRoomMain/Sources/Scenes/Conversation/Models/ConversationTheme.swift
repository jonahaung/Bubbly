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
    let backgroundColor: Color
    let outgoingBubbleColor: Color
    let incomingBubbbleColor: Color
    let bubbleCornorRadius: CGFloat
    let shadowColor: Color
    let incomingForegroundColor: Color
    let outgoingForegroundColor: Color
	let bubblePading: EdgeInsets

    public init(_ conversation: Conversation) {
        let theme = conversation.properties.theme
        backgroundColor = theme.background.color
        outgoingBubbleColor = theme.outgoingBubbleColor
        incomingBubbbleColor = theme.incomingBubbleColor
        bubbleCornorRadius = theme.bubbleCornorRadius
        shadowColor = Color.opaqueSeparator
        incomingForegroundColor = Color.primary
        outgoingForegroundColor = Color.black
		bubblePading = .init(
			top: UIFont.labelFontSize * 0.5,
			leading: UIFont.labelFontSize * 0.7,
			bottom: UIFont.labelFontSize * 0.5,
			trailing: UIFont.labelFontSize * 0.7
		)
    }

	public static let empty = ConversationTheme(
		Conversation(.system(AI.contact), properties: .init(uid: AI.contact.uid))
	)

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
