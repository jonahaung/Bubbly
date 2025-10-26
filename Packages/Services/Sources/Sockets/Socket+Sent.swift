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
	func send(_ data: AnyMsgData, conversation: any ConversationRepresentable) {
		switch data {
		case .newMsg(let rMsg):
			queue.addOperation { [self] in
				var msg = Message(rMsg)
				try await Store.shared.msgStore.insert(msg)
				await notifyMessage(data)
				msg.outgoingStatus = try await sendToRemote(
					.newMsg(rMsg: rMsg),
					conversation: conversation
				)
				try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
					model.update(with: msg)
				}
				await notifyMessage(.updatedMsg(rMsg: .init(msg: msg)))
			}
		case .updatedMsg(let rMsg):
			queue.addOperation { [self] in
				try await sendToRemote(.updatedMsg(rMsg: rMsg), conversation: conversation)
				try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { model in
					model.update(with: rMsg)
				}
				await notifyMessage(data)
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
				await notifyMessage(data)
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

	@discardableResult func sendToRemote(_ data: AnyMsgData, conversation: any ConversationRepresentable) async throws -> [String: MsgOutgoingStatus] {
		let contacts = await ConversationRepo.getContacts(from: conversation).filter {
			$0.uid != currentUserId
		}
		let title = data.pushNotificationTitle(for: conversation)
		return try await sendToRemote(data, title: title, contacts: contacts)
	}

	@discardableResult func sendToRemote(_ data: AnyMsgData, title: String, contacts: [Contact]) async throws -> [String: MsgOutgoingStatus] {
		let encoded = try JSONEncoder().encode(data)
		guard let encodedString = String(data: encoded, encoding: .utf8) else {
			throw SocketError.encodingFailed
		}

		let results = try await withThrowingTaskGroup(of: (Contact, Bool).self) { group in

			for contact in contacts {
				group.addTask { [self, pushNotificationSender] in
					// Skip empty push tokens or missing public keys
					guard !contact.pushToken.isWhitespace,
						  let publicKeyString = contact.publicKeyString else {
						return (contact, false)
					}

					// Encrypt payload
					let encrypted = try await self.encrypt(
						encodedString,
						publicKeyString: publicKeyString
					)

					// Build APNs notification
					let notification = APNSNotification(
						deviceToken: contact.pushToken,
						messageContent: encrypted,
						title: title
					)

					// Attempt sending
					let success = try? await pushNotificationSender.send(notification: notification)
					return (contact, success != nil)
				}
			}

			// Collect results from all tasks
			var collected = [(Contact, Bool)]()
			for try await result in group {
				collected.append(result)
			}
			return collected
		}

		// Convert to outgoing status dictionary
		var outgoingStatus = [String: MsgOutgoingStatus]()
		results.forEach { (contact, isSuccess) in
			outgoingStatus[contact.uid] = isSuccess ? .sent : .sendingFailed
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
	@MainActor func notifyMessage(_ data: AnyMsgData) {
		NotificationCenter.default
			.post(name: .msgNoti(for: data.conID), object: data)
	}
}
