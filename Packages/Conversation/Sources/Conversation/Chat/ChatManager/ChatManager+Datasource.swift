//  ChatManager+Datasource.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

extension ChatManager {
    func reloadConversation(refetch: Bool) async throws {
        state = try await conversationDataUpdater.reloadConversation(
            currentState: state, refetch: refetch
        )
    }

    func setIncomingMsgsAsRead(before date: Date = .now) async throws {
        let newlyReadMsgs = try await conversationDataUpdater.markReadToUnreadIncomingMsgs(conID: conversationConfig.conID, lessThan: date)
        if newlyReadMsgs.isEmpty {
            return
        }
        for msg in newlyReadMsgs { models.update(msg: msg) }
        if let lastReadMsg = newlyReadMsgs.last {
            try await conversationDataUpdater.sendRecipientStatus(
                lastReadMsg: lastReadMsg,
                conversation: state.conversation
            )
        }
    }
}
