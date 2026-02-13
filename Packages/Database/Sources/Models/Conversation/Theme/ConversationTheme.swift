import Foundation
import SwiftUI
import XUI

public struct ConversationTheme: Codable, Sendable, Hashable {
	public var bubbleColor: BubbleColor
	public var background: ChatBackground
	public var bubbleCornorRadius: CGFloat

	public init(bubbleColor: BubbleColor = .default,
	            background: ChatBackground = .default,
	            bubbleCornorRadius: CGFloat = 17)
	{
		self.bubbleColor = bubbleColor
		self.background = background
		self.bubbleCornorRadius = bubbleCornorRadius
	}

	public static let `default` = ConversationTheme(
		bubbleColor: .default,
		background: .default,
		bubbleCornorRadius: 17
	)
}

public extension ConversationTheme {
	var isDarkMode: Bool {
		UITraitCollection.current.userInterfaceStyle == .dark
	}

	var incomingBubbleColor: Color {
		.tertiarySystemBackground
	}

	var outgoingBubbleColor: Color {
		bubbleColor.value
	}

	var shadowColor: Color {
		UITraitCollection.current.userInterfaceStyle == .light
			? .init(
				white: 0.75
			)
			: .init(
				white: 0.0
			)
	}

	var bubblePadding: CGFloat {
		max(12, bubbleCornorRadius / 2)
	}
}
