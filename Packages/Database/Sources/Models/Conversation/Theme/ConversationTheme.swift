//
//  ConversationTheme.swift
//  Database
//
//  Created by Aung Ko Min on 12/10/25.
//

import Foundation
import SwiftUI
import XUI

public struct ConversationTheme: Codable, Sendable, Hashable {
	public var bubbleColor: BubbleColor
	public var background: ChatBackground
	public var bubbleCornorRadius: CGFloat

	public init(
		bubbleColor: BubbleColor = .default,
		background: ChatBackground = .default,
		bubbleCornorRadius: CGFloat = 17
	) {
		self.bubbleColor = bubbleColor
		self.background = background
		self.bubbleCornorRadius = bubbleCornorRadius
	}

	public static let `default` = ConversationTheme(
		bubbleColor: .whatsApp,
		background: .default,
		bubbleCornorRadius: 17
	)
}

extension ConversationTheme {
	public var incomingBubbleColor: Color {
		background == .system ? .tertiarySystemGroupedBackground : .tertiarySystemBackground
	}

	public var outgoingBubbleColor: Color {
		bubbleColor.color
	}

	public var shadowColor: Color {
		UITraitCollection.current.userInterfaceStyle == .light
			? .init(
				white: 0.75
			)
			: .init(
				white: 0.0
			)
	}

	public var bubblePadding: CGFloat {
		max(12, bubbleCornorRadius / 2)
	}
}
