//
//  ChatManager+Models.swift
//  Conversation
//
//  Created by Aung Ko Min on 19/4/26.
//

import Foundation
import Database

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
