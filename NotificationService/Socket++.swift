//
//  Socket++.swift
//  Bubbly
//
//  Created by Aung Ko Min on 26/8/25.
//

import Foundation
import Database
import Services
import XUI

extension Socket {

	func handleReceive(_ data: AnyMsgData) async throws {
		switch data {
		case .newMsg(let rMsg):
			try await ConversationRepo.getOrCreate(
				for: rMsg.conID, refetch: false
			)
			try await Store.shared.msgStore.insert(Message(rMsg))
		case .updatedMsg(let rMsg):
			try await Store.shared.msgStore.updateAndSave(uid: rMsg.uid) { pMsg in
				pMsg.update(with: rMsg)
			}
		case .deleteMsg(let rMsg):
			try await Store.shared.msgStore.delete(uid: rMsg.uid)
		case .reaction:
			break
		case .typingStatus:
			break
		case .seenStatus(status: let status):
			let seenMember = SeenMember(
				uid: status.userID,
				msgId: status.msgID,
				date: ServerTime.now.value
			)
			let conversation = try await ConversationRepo.getOrCreate(for: status.conID, refetch: false)
			switch conversation.kind {
			case .contact(_):
				fatalError()
			case .group(let group):
				try await Store.shared.groupStore
					.updateAndSave(uid: group.uid) { model in
						model.seenMembers.replace(seenMember)
					}
			case .system( _):
				fatalError()
			}

		}
	}
}
