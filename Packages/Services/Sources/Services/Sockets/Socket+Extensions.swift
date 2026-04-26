// © 2026 Aung Ko Min

import Core
import Database
import XUI

public extension Socket {
    
    func handleReceiveBackground(_ data: AnyMsgData) async throws {
        try await queue.addOperation { [weak self] in
            guard let self else { return }
            try await applyToLocalStore(data)
        }
    }
}

private extension Socket {
    func applyToLocalStore(_ data: AnyMsgData) async throws {
        switch data {
        case let .newMsg(rMsg):
            try await ConversationRepo.getOrCreate(
                for: rMsg.conID,
                refetch: false,
            )
            try await ConversationPropertiesRepo.getOrCreate(
                for: rMsg.conID,
                refetch: false,
            )
            if try await Store.shared.msgStore?.exists(uid: rMsg.uid) != true {
                var msg = Message(rMsg)
                msg.incomingStatus = .delivered
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
                }) == true
                model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
                if !isSame {
                    model.reactions.append(payload.reaction)
                }
            }
        case .typingStatus:
            break
        case .msgRecipientReceipt(payload: let payload):
            if payload.recipientReceipt.status == .read {
                var properties = try await ConversationPropertiesRepo.getOrCreate(
                    for: payload.conID,
                    refetch: false,
                )
                properties.seenMembers.removeAll(where: { $0.uid == payload.recipientReceipt.userID })
                properties.seenMembers.append(.init(uid: payload.recipientReceipt.userID, msgId: payload.msgID, date: payload.recipientReceipt.date.value))
                try await Store.shared
                    .conversationPropertiesStore?
                    .updateAndSave(uid: payload.conID) { model in
                        model.update(from: properties)
                    }
            }
            try await Store.shared.msgStore?.updateAndSave(uid: payload.msgID) { model in
                model.outgoingStatus?.updatingReceipt(memberID: payload.recipientReceipt.userID, state: payload.recipientReceipt.status)
            }
            
            let msgs = try await MsgRepo.outgoingUnreadMsgs(conID: payload.conID).filter { $0.date < payload.recipientReceipt.date.date }
            AsyncOrderedStream.streamOrdered(inputs: msgs) { [weak self] msg in
                guard let self else { return }
                var msg = msg
                msg.outgoingStatus?.updatingReceipt(
                    memberID: payload.recipientReceipt.userID,
                    state: payload.recipientReceipt.status
                )
                try await Store.shared.msgStore?.updateAndSave(uid: msg.uid) { model in
                    model.update(from: msg)
                }
            }
        }

        let appState = AppStateStore.read()
        if appState == .background {
            var dataArray = GroupStorage.shared.codable(
                [AnyMsgData].self,
                for: .device(.anyMsgData),
            ) ?? []
            dataArray.append(data)
            GroupStorage.shared.save(dataArray, for: .device(.anyMsgData))
        }
    }
}
