//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import FCM_V1
import Foundation
import XUI

extension Socket {
    public static func send(_ data: AnyMsgData, conversation: Conversation) async throws {
        try await Task { @SocketActor in
            try await Socket.shared.send(data, conversation: conversation)
        }
        .value
    }

    func send(_ data: AnyMsgData, conversation _: Conversation) async throws {
        switch data {
        case let .newMsg(rMsg):
            let msg = Message(rMsg)
            try await Store.shared.msgStore?.insert(msg)
            notifyMessage(data)
            if msg.isSender {
                addToQueue()
            }
        case let .deleteMsg(rMsg: rMsg):
            try await Store.shared.msgStore?.delete(uid: rMsg.uid)
            notifyMessage(data)
            if rMsg.senderID == currentUserId {
                addToQueue()
            }
        case let .reaction(payload):
            try await Store.shared.msgStore?.updateAndSave(uid: payload.msgID) { model in
                let isSame = model.reactions.contains(
                    where: {
                        $0.senderID == payload.reaction.senderID && $0.rawValue == payload.reaction
                            .rawValue
                    }
                )
                model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
                if !isSame {
                    model.reactions.append(payload.reaction)
                }
            }
            notifyMessage(data)
            addToQueue()
        default:
            addToQueue()
        }
        func addToQueue() {
            if sendingQueue.isEmpty {
                sendingQueue.enqueue(data)
                dequeueIfNeeded()
            } else {
                sendingQueue.enqueue(data)
            }
        }
    }

    private func dequeueIfNeeded() {
        guard let data = sendingQueue.dequeue() else { return }
        Task { [weak self] in
            guard let self else { return }
            try await queue.sync { [weak self] in
                guard let self else { return }
                defer {
                    Task { [weak self] in
                        guard let self else { return }
                        try await Task.sleep(seconds: 1)
                        await self.dequeueIfNeeded()
                    }
                }
                try await self.performSend(data)
            }
        }
    }

    private func performSend(_ data: AnyMsgData) async throws {
        let conversation = try await ConversationRepo.getOrCreate(
            for: data.conID,
            refetch: false
        )
        switch data {
        case let .newMsg(rMsg):
            var msg = Message(rMsg)
            msg.outgoingStatus = try await sendToRemote(
                .newMsg(rMsg: rMsg),
                conversation: conversation
            )
            try await Store.shared.msgStore?.updateAndSave(uid: rMsg.uid) { model in
                model.update(from: msg)
            }
            notifyMessage(.updatedMsg(rMsg: .init(msg)))
        case let .updatedMsg(rMsg):
            try await sendToRemote(.updatedMsg(rMsg: rMsg), conversation: conversation)
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
        case let .seenStatus(status: status):
            guard
                let msg = try await Store.shared.msgStore?.fetch(
                    uid: status.msgID
                )
            else {
                return
            }
            guard let contact = await ContactsRepository.shared.contact(for: msg.senderID) else {
                return
            }
            let title = data.pushNotificationTitle(for: conversation)
            let body = data.pushNotificationSubtitle
            try await sendToRemote(
                data,
                alert: .init(title: title, body: body),
                contacts: [contact]
            )
        }
    }

    @discardableResult public func sendToRemote(
        _ data: AnyMsgData,
        conversation: Conversation
    ) async throws -> [
        String: MsgOutgoingStatus
    ] {
        let contacts = try await getContacts(
            from: conversation
        ).filter {
            $0.uid != currentUserId
                && isValidDeviceToken(
                    $0.pushToken
                )
        }
        let title = data.pushNotificationTitle(for: conversation)
        return try await sendToRemote(
            data,
            alert: .init(title: title, body: data.pushNotificationSubtitle),
            contacts: contacts
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
        contacts: [Contact]
    ) async throws -> [
        String: MsgOutgoingStatus
    ] {
        let encoded = try JSONEncoder().encode(data)
        guard let encodedString = String(data: encoded, encoding: .utf8) else {
            throw SocketError.encodingFailed
        }
        let results: [(Contact, Bool)] = try await AsyncOrderedStream.mapOrdered(
            inputs: contacts
        ) { contact in
            let encrypted = try await self.encrypt(
                encodedString,
                publicKeyString: contact.publicKeyString
            )

            // Build APNs notification
            let notification = APNSNotification(
                deviceToken: contact.pushToken,
                messageContent: encrypted,
                alert: alert
            )
            let success = try? await self.pushNotificationSender.send(notification: notification)
            return (contact, success != nil)
        }
        var outgoingStatus = [String: MsgOutgoingStatus]()
        for (contact, isSuccess) in results {
            outgoingStatus[contact.uid] = isSuccess ? .sent : .sendingFailed
        }

        return outgoingStatus
    }

    private func encrypt(_ dataString: String, publicKeyString: String) async throws -> String {
        guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
            throw SocketError.encryptionFailed
        }
        return try cryptoService.encrypt(
            dataString: dataString,
            recipientPublicKeyString: publicKeyString, currentUserID: currentUserID
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
