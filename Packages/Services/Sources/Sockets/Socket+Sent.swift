//
//  Socket+Sent.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Core
import Database
import FCM_V1
import Foundation
import XUI

extension Socket {
	public func send(_ data: AnyMsgData, conversation: Conversation) async throws {
		switch data {
		case let .newMsg(rMsg):
			let msg = Message(rMsg)
			try await Store.shared.msgStore.insert(msg)
			notifyMessage(data)
			if msg.isSender {
				addToQueue()
			}
		case let .deleteMsg(rMsg: rMsg):
			try await Store.shared.msgStore.delete(uid: rMsg.uid)
			notifyMessage(data)
			if rMsg.uid == currentUserId {
				addToQueue()
			}
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
			await queue.addOperation { [weak self] in
				guard let self else { return }
				debugPrint("dequeue")
				try await performSend(data)
				try await Task.sleep(seconds: 1)
				await dequeueIfNeeded()
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
			switch conversation.kind {
			case .contact, .group:
				msg.outgoingStatus = try await sendToRemote(
					.newMsg(rMsg: rMsg),
					conversation: conversation
				)
				try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
					model.update(from: msg)
				}
				notifyMessage(.updatedMsg(rMsg: .init(msg)))
			case .system:
				break
			}
		case let .updatedMsg(rMsg):
			try await sendToRemote(.updatedMsg(rMsg: rMsg), conversation: conversation)
			try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
				model.update(with: rMsg)
			}
			notifyMessage(data)
		case .typingStatus:
			try await sendToRemote(data, conversation: conversation)
		case let .reaction(reaction):
			debugPrint(reaction)
		case .deleteMsg:
			try await sendToRemote(data, conversation: conversation)
		case let .seenStatus(status: status):
			guard
				let msg = try await Store.shared.msgStore.fetch(
					uid: status.msgID
				)
			else {
				return
			}
			guard let contact = await ContactStore.shared.contact(for: msg.senderID) else {
				return
			}
			let title = data.pushNotificationTitle(for: conversation)
			try await sendToRemote(
				data,
				title: title,
				contacts: [contact]
			)
		}
	}

	@discardableResult public func sendToRemote(
		_ data: AnyMsgData,
		conversation: Conversation
	) async throws -> [String: MsgOutgoingStatus] {
		let contacts = try await getContacts(
			from: conversation
		).filter {
			$0.uid != currentUserId
			&& isValidDeviceToken(
				$0.pushToken
			)
		}
		let title = data.pushNotificationTitle(for: conversation)
		return try await sendToRemote(data, title: title, contacts: contacts)
	}

	private func getContacts(
		from conversation: Conversation
	) async throws -> [Contact] {
		switch conversation.kind {
		case let .contact(contact):
			[contact]
		case let .group(group):
			try await ContactRepo.getOrCreate(for: group.members, refatch: false)
		case .system:
			[]
		}
	}

	@discardableResult public func sendToRemote(
		_ data: AnyMsgData,
		title: String,
		contacts: [Contact]
	) async throws -> [String: MsgOutgoingStatus] {
		let encoded = try JSONEncoder().encode(data)
		guard let encodedString = String(data: encoded, encoding: .utf8) else {
			throw SocketError.encodingFailed
		}
		let results:
		[(
			Contact,
			Bool
		)] = try await AsyncOrderedStream.mapOrdered(
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
				title: title
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
		let encrypted = cryptoService.encrypt(
			dataString: dataString,
			publicKeyString: publicKeyString
		)
		return cryptoService.createPayload(for: encrypted)
	}

	public func notifyMessage(_ data: AnyMsgData) {
		NotificationCenter.default
			.post(name: .msgNoti(for: data.conID), object: data)
	}

	private func isValidDeviceToken(_ token: String) -> Bool {
		!token.isWhitespace
	}
}
