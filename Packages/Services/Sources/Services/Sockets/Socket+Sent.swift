// © 2026 Aung Ko Min

import Core
import Database
import FCM_V1
import Foundation
import XUI

public extension Socket {
    
    func send(_ data: AnyMsgData) async throws {
        switch data {
        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            notifyMessage(data)
            try await Store.shared.msgStore?.insert(msg)
            try await Task.sleep(seconds: 0.5)
            if msg.isSender {
                addToQueue()
            }
        case let .deleteMsg(rMsg: rMsg):
            let currentUserID = try CurrentUserID.get()
            try await Store.shared.msgStore?.delete(uid: rMsg.uid)
            notifyMessage(.newMsg(rMsg: rMsg))
            if rMsg.senderID == currentUserID {
                addToQueue()
            }
        case let .reaction(payload):
            try await Store.shared.msgStore?.updateAndSave(uid: payload.msgID) { model in
                model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
                model.reactions.append(payload.reaction)
            }
            notifyMessage(data)
            addToQueue()
        default:
            addToQueue()
        }
        func addToQueue() {
            queue.addOperation { [weak self] in
                guard let self else { return }
                try await performSend(data)
            }
        }
    }

    public func performSend(_ data: AnyMsgData) async throws {
        let conversation = try await ConversationRepo.getOrCreate(
            for: data.conID,
            refetch: false,
        )
        switch data {
        case let .newMsg(rMsg):
            var msg = Message(rMsg)
            let receipts = try await sendToRemote(
                .newMsg(rMsg: rMsg.outgoing()),
                conversation: conversation,
            )
            msg.outgoingStatus = msg.outgoingStatus?.replacingReceipts(receipts)
            try await Store.shared.msgStore?.updateAndSave(uid: rMsg.uid) { model in
                model.update(from: msg)
            }
            notifyMessage(.updatedMsg(rMsg: .init(msg)))
        case let .updatedMsg(rMsg):
            try await sendToRemote(.updatedMsg(rMsg: rMsg.outgoing()), conversation: conversation)
            try await Store.shared.msgStore?.updateAndSave(uid: rMsg.uid) { model in
                model.update(with: rMsg)
            }
            notifyMessage(data)
        case .typingStatus:
            try await sendToRemote(data, conversation: conversation)
        case .reaction:
            try await sendToRemote(data, conversation: conversation)
        case .deleteMsg:
            try await sendToRemote(data, conversation: conversation)
        case .msgRecipientReceipt(let payload):
            try await sendToRemote(data, conversation: conversation)
        }
    }

    @discardableResult public func sendToRemote(
        _ data: AnyMsgData,
        conversation: Conversation,
    ) async throws -> [MsgRecipientReceipt] {
        let currentUserID = try CurrentUserID.get()
        let contacts = try await getContacts(
            from: conversation,
        ).filter {
            $0.uid != currentUserID
                && isValidDeviceToken(
                    $0.pushToken,
                )
        }
        let title = data.pushNotificationTitle(for: conversation)
        return try await sendToRemote(
            data,
            alert: .init(
                title: title,
                subtitle: nil,
                body: data.pushNotificationBody,
            ),
            contacts: contacts,
        )
    }

    private func getContacts(from conversation: Conversation) async throws -> [Contact] {
        switch conversation.kind {
        case let .contact(contact):
            [contact]
        case let .group(group):
            try await ContactRepo.getOrCreate(for: group.members, refatch: false)
        }
    }

    @discardableResult public func sendToRemote(
        _ data: AnyMsgData,
        alert: APNSAlert,
        contacts: [Contact],
    ) async throws -> [MsgRecipientReceipt] {
        let encoded = try JSONEncoder().encode(data)
        guard let encodedString = String(data: encoded, encoding: .utf8) else {
            throw SocketError.encodingFailed
        }

        return try await AsyncOrderedStream.mapOrdered(
            inputs: contacts,
        ) { contact in
            let encrypted = try await self.encrypt(
                encodedString,
                publicKeyString: contact.publicKeyString,
            )
            let deepLink = DeeplinkCodec.standard
                .url(for: .conversation(conID: data.conID))?
                .absoluteString

            let notification = APNSNotification(
                deviceToken: contact.pushToken,
                messageContent: encrypted,
                alert: alert,
                interruptionLevel: .timeSensitive,
                customData: [
                    "con_id": data.conID,
                    "deep_link": deepLink ?? "",
                ]
            )
            let success = try? await self.pushNotificationSender.send(notification: notification)
            return MsgRecipientReceipt(
                memberID: contact.uid,
                state: success == nil ? .partiallyFailed : .delivered,
                updatedAt: .now,
                failure: success == nil ? .init(code: "push_failed", isRetryable: true) : nil
            )
        }
    }

    private func encrypt(_ dataString: String, publicKeyString: String) throws -> String {
        guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
            throw SocketError.encryptionFailed
        }

        return try cryptoService.encrypt(
            dataString: dataString,
            recipientPublicKeyString: publicKeyString, currentUserID: currentUserID,
        )
    }

    public func notifyMessage(_ data: AnyMsgData) {
        NotificationCenter.default
            .post(name: .msgNoti(for: data.conID), object: data)
    }

    private func isValidDeviceToken(_ token: String) -> Bool {
        !token.isWhitespace
    }
}
