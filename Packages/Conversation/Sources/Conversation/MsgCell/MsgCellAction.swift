// © 2026 Aung Ko Min

import Database
import SwiftUI

// MARK: - MsgCellAction

struct MsgCellAction {
    enum ActionType {
        case onTapMsg(String)
        case onMarkMsg(Message)
        case onTapAvatar(String)
        case onFocusMsgBubble(_ item: OverlayMenuItem?)
        case onUploadedAttachments(Message)
        case onReact(Message, ReactionType)
    }

    let action: (ActionType) -> Void
    func callAsFunction(_ type: ActionType) {
        action(type)
    }
}

extension EnvironmentValues {
    @Entry var msgCellActions: MsgCellAction?
}
