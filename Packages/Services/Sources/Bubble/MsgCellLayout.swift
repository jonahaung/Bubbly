//
//  MsgCellLayout.swift
//  Services
//
//  Created by Aung Ko Min on 10/10/25.
//

import Core
import XUI

public struct MsgCellLayout: Conformable {
    public let showTimeSeparator: Bool
    public let showTopPadding: Bool
    public let bubble: Bubble
    public var isSelected: Bool = false

    public init(showTimeSeparator: Bool, showTopPadding: Bool, bubble: Bubble) {
        self.showTimeSeparator = showTimeSeparator
        self.showTopPadding = showTopPadding
        self.bubble = bubble
    }

    public init() {
        self.init(showTimeSeparator: false, showTopPadding: false, bubble: .init())
    }

    public var isEmpty: Bool {
        bubble.bubbleCorner == .none
    }
}
