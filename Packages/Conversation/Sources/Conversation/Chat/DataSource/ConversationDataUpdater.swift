// © 2026 Aung Ko Min

import Database
import Foundation
import Services
import XUI

struct ConversationDataUpdater {
    func reloadConversation(currentState: ChatManager.State, refetch: Bool)
        async throws
        -> ChatManager.State
    {
        let conID = currentState.conversation.uid
        var updatedState = currentState
        updatedState.properties =
            try await ConversationPropertiesRepo.getOrCreate(
                for: conID,
                refetch: refetch,
            )
        updatedState.conversation = try await ConversationRepo.getOrCreate(
            for: conID,
            refetch: refetch,
        )
        updatedState.theme = .init(updatedState.properties.theme)
        return updatedState
    }

    func updateMsgs(
        before date: Date,
        of recipient: MsgRecipient,
        from fromStatus: DeliveryStatus,
        to toStatus: DeliveryStatus,
        currentState: ChatManager.State,
        currentUserID: String,
    ) async throws -> [Message] {
        let conID = currentState.conversation.uid
        let msgs = try await MsgRepo.msgs(
            conID: conID,
            deliveryStatus: fromStatus,
            recipient: recipient,
            currentUserID: currentUserID,
        )
        .filter { $0.date <= date }
        guard let store = await Store.shared.msgStore else {
            return []
        }

        let results = try await AsyncOrderedStream.mapOrdered(inputs: msgs) {
            msg in
            var mutable = msg
            mutable.deliveryStatus = toStatus
            return try await store.updateAndSave(uid: msg.uid) { model in
                model.update(from: mutable)
                return mutable
            }
        }
        return results.compactMap(\.self)
    }

    func sendSeenStatus(
        lastReadMsg: Message,
        currentUserID: String,
        conversation: Conversation
    )
        async throws
    {
        try await Socket.send(
            .seenStatus(
                status: .init(
                    msgID: lastReadMsg.uid,
                    userID: currentUserID,
                    conID: lastReadMsg.conID,
                    date: ServerTime.now.value,
                ),
            ),
            conversation: conversation,
        )
    }
}
