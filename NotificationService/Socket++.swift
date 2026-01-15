//
//  Socket++.swift
//  Bubbly
//
//  Created by Aung Ko Min on 26/8/25.
//

import Database
import Foundation
import Services
import XUI

extension Socket {
	func handleReceive(_ data: AnyMsgData) async throws {
		switch data {
		case .newMsg(let rMsg):
			try await ConversationRepo.getOrCreate(
				for: rMsg.conID,
				refetch: false
			)
			try await Store.shared.msgStore.insert(Message(rMsg))
		case .updatedMsg(let rMsg):
			try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { pMsg in
				pMsg.update(with: rMsg)
			}
		case .deleteMsg(let rMsg):
			try await Store.shared.msgStore.delete(uid: rMsg.uid)
		case let .reaction(payload):
			try await Store.shared.msgStore.updateAndSave(uid: payload.msgID) { model in
				let isSame = model.reactions.contains(
					where: { $0.senderID == payload.reaction.senderID && $0.rawValue == payload.reaction.rawValue })
				model.reactions.removeAll(where: { $0.senderID == payload.reaction.senderID })
				if !isSame {
					model.reactions.append(payload.reaction)
				}
			}
		case .typingStatus:
			break
		case .seenStatus(status: let status):
			let seenMember = SeenMember(
				uid: status.userID,
				msgId: status.msgID,
				date: ServerTime.now.value
			)
			var conversation = try await ConversationRepo.getOrCreate(for: status.conID, refetch: false)
			conversation.properties.seenMembers.removeAll(where: { $0.uid == status.userID })
			conversation.properties.seenMembers.append(seenMember)
			try await Store.shared.msgStore.updateAndSave(uid: status.msgID) { msg in
				msg.outgoingStatus[status.userID] = .sent
			}
			try await conversation.saveChanges()
		}
	}
}
