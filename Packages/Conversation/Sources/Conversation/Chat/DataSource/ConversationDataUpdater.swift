//  ConversationDataUpdater.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Database
import Foundation
import Services
import XUI

struct ConversationDataUpdater {

    func reloadState(currentState: ChatManager.State, refetch: Bool) async throws -> ChatManager.State {
        let conversationID = currentState.conversation.uid

        var updatedState = currentState
        updatedState.properties = try await ConversationPropertiesRepo.getOrCreate(
            for: conversationID, refetch: refetch)
        updatedState.conversation = try await ConversationRepo.getOrCreate(for: conversationID, refetch: refetch)
        updatedState.theme = .init(updatedState.properties.theme)

        return updatedState
    }

    func markReadToUnreadIncomingMsgs(conID: String, lessThan date: Date) async throws -> [Message] {
        let unreadMessages = try await MsgRepo.incomingUnreadMsgs(conID: conID).filter { $0.date <= date }

        return try await AsyncOrderedStream.mapOrdered(inputs: unreadMessages) { message in
            var updatedMessage = message
            updatedMessage.incomingStatus = .read

            try await Store.shared.msgStore?.updateAndSave(uid: updatedMessage.uid) { model in
                model.update(from: updatedMessage)
            }
            return updatedMessage
        }
    }

    func sendRecipientStatus(lastReadMsg: Message) async throws {
        let currentUserID = try CurrentUserID.get()
        let receipt = MsgRecipientReceipt(memberID: currentUserID, state: .read, updatedAt: .now)
        let payload = AnyMsgData.MsgRecipientReceiptPayload(
            msgID: lastReadMsg.uid,
            conID: lastReadMsg.conID,
            recipientReceipt: receipt
        )

        try await Socket.shared.send(.msgRecipientReceipt(payload: payload))
    }
}
