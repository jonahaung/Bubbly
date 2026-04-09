// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension ChatManager {
    func reloadConversation(refetch: Bool) async throws {
        state =
            try await conversationDataUpdater
                .reloadConversation(currentState: state, refetch: refetch)
    }

    func setIncomingMsgsAsRead() async throws {
        guard let currentUserID = await currentUserRepository?.model.uid else {
            return
        }

        let updatedMsgs = try await conversationDataUpdater.updateMsgs(
            before: .now,
            of: .incoming,
            from: .received,
            to: .read,
            currentState: state,
            currentUserID: currentUserID,
        )
        for msg in updatedMsgs {
            models.update(msg: msg)
        }
        if let lastReadMsg = updatedMsgs.last {
            try await conversationDataUpdater
                .sendSeenStatus(
                    lastReadMsg: lastReadMsg,
                    currentUserID: currentUserID,
                    conversation: state
                        .conversation,
                )
        }
    }

    func setOutgoingMsgsAsRead(status: AnyMsgData.SeenStatusPayload) async throws {
        guard let msg = try await Store.shared.msgStore?.fetch(uid: status.msgID) else {
            return
        }

        let msgIDs = models.renderedModels
            .filter {
                $0.msg.receiptType == .outgoing && $0.state.date <= msg.date
                    && $0.state.deliveryStatus == .delivered
            }
            .map(\.value.id)

        let msgs = try await AsyncOrderedStream.mapOrdered(inputs: msgIDs) { msgID in
            try await Store.shared.msgStore?.fetch(uid: msgID)
        }.compactMap(\.self)

        for msg in msgs {
            models.update(msg: msg)
        }
    }
}
