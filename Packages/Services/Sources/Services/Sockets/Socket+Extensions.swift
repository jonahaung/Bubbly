// © 2026 Aung Ko Min

import Core
import Database
import XUI

public extension Socket {
    func receive(_ data: AnyMsgData) async throws {
        try await queue.sync {
            try await self.applyToLocalStore(data)
            await self.notifyMessage(data)
        }
    }
}

private extension Socket {
    func applyToLocalStore(_ data: AnyMsgData) async throws {
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
            try await Store.shared.msgStore?.updateAndSave(uid: rMsg.uid) { model in
                model.update(with: rMsg)
            }
        case let .reaction(payload):
            try await Store.shared.msgStore?.updateAndSave(uid: payload.msgID) { model in
                let isSameReaction = model.reactions.contains(where: {
                    $0.senderID == payload.reaction.senderID && $0.rawValue == payload.reaction.rawValue
                })
                model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
                if !isSameReaction {
                    model.reactions.append(payload.reaction)
                }
            }
        case let .deleteMsg(rMsg):
            try await Store.shared.msgStore?.delete(uid: rMsg.uid)
        case let .seenStatus(status):
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
            try await MsgRepo.updateSentMsgs(
                statusPayload: status,
                currentUserID: currentUserID
            )
        case .typingStatus:
            break
        }
    }
}
