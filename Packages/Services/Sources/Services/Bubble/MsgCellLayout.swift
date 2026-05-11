// © 2026 Aung Ko Min

import Core
import XUI

public struct MsgCellLayout: Conformable {
    
    public var id: Int {
            var hasher = Hasher()
            hasher.combine(showTimeSeparator)
            hasher.combine(bubbleCorner)
            hasher.combine(showTopPadding)
            return hasher.finalize()
        }
    
    public let showTimeSeparator: Bool
    public let showTopPadding: Bool
    public var bubbleCorner: BubbleCorner

    public init(
        showTimeSeparator: Bool,
        showBottomPadding: Bool,
        bubbleCorner: BubbleCorner,
    ) {
        self.showTimeSeparator = showTimeSeparator
        self.showTopPadding = showBottomPadding
        self.bubbleCorner = bubbleCorner
    }

    public init() {
        self.init(
            showTimeSeparator: false,
            showBottomPadding: false,
            bubbleCorner: .none,
        )
    }

    public var isEmpty: Bool {
        bubbleCorner == .none
    }

    public var showAvatar: Bool {
        bubbleCorner == .all || bubbleCorner == .receivingBottom
    }
    
    public mutating func invalidate() {
        self = .init()
    }
}
