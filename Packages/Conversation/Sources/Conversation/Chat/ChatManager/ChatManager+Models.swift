//  ChatManager+Models.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Foundation

extension ChatManager {
    struct State: Equatable {
        var reloadID: Int
        var conversation: Conversation
        var theme: ChatTheme
        var properties: ConversationProperties
    }

    enum Intent {
        case scrollViewIntent(_ newValue: ScrollCoordinator.Intent)
        case scrollDownButtonTapped
        case cellAction(_ newValue: MsgCellAction.ActionType)
    }
}
