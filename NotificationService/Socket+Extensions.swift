//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Foundation
import Services
import XUI

extension Socket {
    public func handleReceive(_ data: AnyMsgData) async throws {
        try await _handleReceive(data)
    }

    private func _handleReceive(_ data: AnyMsgData) async throws {
        switch data {
        case let .newMsg(rMsg):
            _ = try await ConversationRepo.getOrCreate(
                for: rMsg.conID,
                refetch: false
            )
            _ = try await ConversationPropertiesRepo.getOrCreate(
                for: rMsg.conID,
                refetch: false
            )
            if try await Store.shared.msgStore?.exists(uid: rMsg.uid) != true {
                var msg = Message(rMsg)
                msg.deliveryStatus = .received
                try await Store.shared.msgStore?.insert(msg)
            }
        case let .updatedMsg(rMsg):
            try await Store.shared.msgStore?.updateAndSave(uid: rMsg.uid) { pMsg in
                pMsg.update(with: rMsg)
            }
        case let .deleteMsg(rMsg):
            try await Store.shared.msgStore?.delete(uid: rMsg.uid)
        case let .reaction(payload):
            try await Store.shared.msgStore?.updateAndSave(uid: payload.msgID) { model in
                let isSame = model.reactions.contains(where: {
                    $0.senderID == payload.reaction.senderID && $0.rawValue == payload.reaction
                        .rawValue
                })
                model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
                if !isSame {
                    model.reactions.append(payload.reaction)
                }
            }
        case .typingStatus:
            break
        case let .seenStatus(status: status):
            var properties = try await ConversationPropertiesRepo.getOrCreate(
                for: status.conID,
                refetch: false
            )
            properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
            properties.seenMembers.append(status.seenMember)
            try await Store.shared.conversationPropertiesStore?
                .updateAndSave(uid: status.conID) { model in
                    model.update(from: properties)
                }
            let currentUserID = try CurrentUserID.get()
            try await MsgRepo.updateSentMsgs(statusPayload: status, currentUserID: currentUserID)
        }

        let appState = AppStateStore.read()
        if appState == .background {
            var dataArray = GroupStorage.shared.codable(
                [AnyMsgData].self,
                for: .device(.anyMsgData)
            ) ?? []
            dataArray.append(data)
            GroupStorage.shared.save(dataArray, for: .device(.anyMsgData))
        }
    }
}

enum NotificationServiceExtensionReceiver {
    static func handleReceive(
        _ data: AnyMsgData,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        Task { @SocketActor in
            do {
                try await Socket.shared.handleReceive(data)
                completion(.success(()))
            } catch {
                completion(.failure(error))
            }
        }
    }
}
