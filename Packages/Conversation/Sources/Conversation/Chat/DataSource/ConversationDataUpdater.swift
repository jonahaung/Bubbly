//  ConversationDataUpdater.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import Database
import Services
import Foundation

struct ConversationDataUpdater {
    func reloadConversation(
        currentState: ChatManager.State, refetch: Bool
    ) async throws -> ChatManager.State {
        let conID = currentState.conversation.uid
        var updatedState = currentState
        updatedState.properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conID, refetch: refetch
        )
        updatedState.conversation = try await ConversationRepo.getOrCreate(
            for: conID, refetch: refetch
        )
        updatedState.theme = .init(updatedState.properties.theme)
        return updatedState
    }

    func markReadToUnreadIncomingMsgs(conID: String, lessThan date: Date) async throws -> [Message] {
        let msgs = try await MsgRepo.incomingUnreadMsgs(conID: conID).filter { $0.date <= date }
        return try await AsyncOrderedStream.mapOrdered(inputs: msgs) { msg in
            var msg = msg
            msg.incomingStatus = .read
            try await Store.shared.msgStore?.updateAndSave(uid: msg.uid) { model in
                model.update(from: msg)
            }
            return msg
        }
    }

    func sendRecipientStatus(
        lastReadMsg: Message
    ) async throws {
        let currentUserID = try CurrentUserID.get()
        try await Socket.shared.send(
            .msgRecipientReceipt(payload: .init(msgID: lastReadMsg.uid, conID: lastReadMsg.conID, recipientReceipt: .init(memberID: currentUserID, state: .read, updatedAt: .now)))
        )
    }
}
