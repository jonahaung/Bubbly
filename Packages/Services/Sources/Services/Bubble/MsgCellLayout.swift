// © 2026 Aung Ko Min

import Core
import XUI

public struct MsgCellLayout: Conformable {
    public let showTimeSeparator: Bool
    public let showTopPadding: Bool
    public var bubbleCorner: BubbleCorner

    public init(
        showTimeSeparator: Bool,
        showTopPadding: Bool,
        bubbleCorner: BubbleCorner,
    ) {
        self.showTimeSeparator = showTimeSeparator
        self.showTopPadding = showTopPadding
        self.bubbleCorner = bubbleCorner
    }

    public init() {
        self.init(
            showTimeSeparator: false,
            showTopPadding: false,
            bubbleCorner: .none,
        )
    }

    public var isEmpty: Bool {
        bubbleCorner == .none
    }

    public var showAvatar: Bool {
        bubbleCorner == .all || bubbleCorner == .receivingBottom
    }
}
