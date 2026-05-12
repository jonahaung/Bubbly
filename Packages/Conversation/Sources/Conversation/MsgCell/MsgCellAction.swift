//  MsgCellAction.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI
import Database

struct MsgCellAction {
    enum ActionType: Sendable {
        case onTapMsg(String)
        case onMarkMsg(Message)
        case onTapAvatar(String)
        case onFocusMsgBubble(_ item: OverlayMenuItem?)
        case onUploadedAttachments(Message)
        case onReact(Message, ReactionType)
        case performSend(AnyMsgData)
    }

    let action: (sending ActionType) -> Void
    func callAsFunction(_ type: ActionType) {
        action(type)
    }
}

extension EnvironmentValues {
    @Entry var msgCellActions: MsgCellAction?
}
