// © 2026 Aung Ko Min

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
        bubbleCornorRadius: CGFloat = 17,
    ) {
        self.bubbleColor = bubbleColor
        self.background = background
        self.bubbleCornorRadius = bubbleCornorRadius
    }

    public static let `default`: ConversationTheme = .init(
        bubbleColor: .default,
        background: .default,
        bubbleCornorRadius: 17,
    )
}
