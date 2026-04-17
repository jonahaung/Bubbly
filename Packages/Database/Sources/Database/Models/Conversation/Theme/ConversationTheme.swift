// © 2026 Aung Ko Min

import Foundation
import SwiftUI
import XUI
import Core

public struct ConversationTheme: Codable, Sendable, Hashable {
    public var bubbleColor: BubbleColor
    public var background: ChatBackground
    public var bubbleCornorRadius: CGFloat

    public init(
		bubbleColor: BubbleColor = .empty,
        background: ChatBackground = .bg_6,
        bubbleCornorRadius: CGFloat = 17,
    ) {
        self.bubbleColor = bubbleColor
        self.background = background
        self.bubbleCornorRadius = bubbleCornorRadius
    }

    public static let `default`: ConversationTheme = .init(
		bubbleColor: .empty,
        background: .bg_6,
        bubbleCornorRadius: 17,
    )
}
