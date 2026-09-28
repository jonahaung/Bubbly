//  MsgCellDecoration.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core

public struct MsgCellDecoration: Hashable, Conformable {

    public var id: Int {
        var hasher = Hasher()
        hasher.combine(showTimeSeparator)
        hasher.combine(showBottomSpacer)
        return hasher.finalize()
    }

    public let showTimeSeparator: Bool
    public let showBottomSpacer: Bool
    public var bubbleCorner: BubbleCorner

    public init(
        showTimeSeparator: Bool,
        showBottomSpacer: Bool,
        bubbleCorner: BubbleCorner
    ) {
        self.showTimeSeparator = showTimeSeparator
        self.showBottomSpacer = showBottomSpacer
        self.bubbleCorner = bubbleCorner
    }

    public var isEmpty: Bool {
        bubbleCorner == .none
    }

    public var showAvatar: Bool {
        bubbleCorner == .all || bubbleCorner == .receivingBottom
    }
}
