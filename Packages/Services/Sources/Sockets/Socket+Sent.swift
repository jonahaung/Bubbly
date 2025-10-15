//
//  Socket+Sent.swift
//  Services
//
//  Created by Aung Ko Min on 26/8/25.
//

import Foundation
import Database
import FCM_V1
import Core

public extension Socket {
	func send(_ data: AnyMsgData, conversation: ConversationSnapshot) {
		switch data {
		case .newMsg(let rMsg):
			queue.addOperation { [self] in
				var msg = MsgSnapshot(rMsg)
				try await Store.shared.msgStore.insert(msg)
				notifyMessage(data)
				let outgoingStatus = try await sendToRemote(
					.newMsg(rMsg: rMsg.serialized()),
					conversation: conversation
				)
				msg.outgoingStatus = outgoingStatus
				try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
					model.update(with: msg)
				}
				notifyMessage(.updatedMsg(rMsg: .init(msg: msg)))
			}
		case .updatedMsg(let rMsg):
			queue.addOperation { [self] in
				try await sendToRemote(.updatedMsg(rMsg: rMsg.serialized()), conversation: conversation)
				try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
					model.update(with: rMsg)
				}
				notifyMessage(data)
			}
		case .typingStatus:
			queue.addOperation { [self] in
				try await sendToRemote(data, conversation: conversation)
			}
		case .reaction(let reaction):
			debugPrint(reaction)
		case .deleteMsg(rMsg: let rMsg):
			queue.addOperation { [self] in
				try await Store.shared.msgStore.delete(uid: rMsg.uid)
				notifyMessage(data)
				try await sendToRemote(data, conversation: conversation)
			}
		case .seenStatus(status: let status):
			queue.addOperation { [self] in
				guard let msg = try await Store.shared.msgStore.fetch(
					uid: status.msgID
				) else {
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
	}

	@discardableResult func sendToRemote(_ data: AnyMsgData, conversation: ConversationSnapshot) async throws -> [String: MsgOutgoingStatus] {
		let contacts = await ConversationRepo.getContacts(from: conversation).filter {
			$0.uid != currentUserId
		}
		let title = data.pushNotificationTitle(for: conversation)
		return try await sendToRemote(data, title: title, contacts: contacts)
	}

	@discardableResult func sendToRemote(_ data: AnyMsgData, title: String, contacts: [ContactSnapshot]) async throws -> [String: MsgOutgoingStatus] {
		let encoded = try JSONEncoder().encode(data)
		guard let encodedString = String(data: encoded, encoding: .utf8) else {
			throw SocketError.encodingFailed
		}
		let pushNotificationSender = PushNotificationSender(
			suitName: AppInformation.groupID
		)
		let results = try await contacts.parallelMap { contact in
			if let publicKeyString = contact.publicKeyString {
				let encrypted = try await self.encrypt(
					encodedString,
					publicKeyString: publicKeyString
				)
				let notification = APNSNotification(
					deviceToken: contact.pushToken,
					messageContent: encrypted,
					title: title
				)
				let success = try? await pushNotificationSender.send(notification: notification)
				return (contact, success == nil ? false : true)
			}
			return (contact, false)
		}

		var outgoingStatus = [String: MsgOutgoingStatus]()
		results.forEach { (contact, isSuccess) in
			outgoingStatus[contact.uid] = isSuccess ? MsgOutgoingStatus.sent : MsgOutgoingStatus.sendingFailed
		}
		return outgoingStatus
	}

	private func encrypt(_ dataString: String, publicKeyString: String) async throws -> String {
		let encrypted = cryptoService.encrypt(
			dataString: dataString,
			publicKeyString: publicKeyString
		)
		return CryptoService.shared.createPayload(for: encrypted)
	}
	func notifyMessage(_ data: AnyMsgData) {
		NotificationCenter.default
			.post(name: .msgNoti(for: data.conID), object: data)
	}
}
