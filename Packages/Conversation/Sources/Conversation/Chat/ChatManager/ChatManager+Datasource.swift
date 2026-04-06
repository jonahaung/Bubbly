//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension ChatManager {
	func reloadConversation(refetch: Bool) async throws {
		var state = state
		state.properties =
			try await ConversationPropertiesRepo
				.getOrCreate(for: conversationConfig.conID, refetch: refetch)
		state.conversation = try await state.conversation.reload(refetch: refetch)
		state.theme = .init(state.properties.theme)
		self.state = state
		layoutIfNeeded()
	}

	func updateReceiveMsgs() {
		Task.detached(priority: .background) { [weak self] in
			guard let self else {
				return
			}
			guard let currentUserID else {
				return
			}
			do {
				let unreadMsgs = try await MsgRepo.updateReceiveMsgs(
					for: conversationConfig.conID,
					currentUserID: currentUserID,
				)
				guard let lastUnreadMsg = unreadMsgs.last else {
					return
				}
				try await Socket.send(
					.seenStatus(
						status: .init(
							msgID: lastUnreadMsg.uid,
							userID: currentUserID,
							conID: lastUnreadMsg.conID,
							date: ServerTime.now.value,
						),
					),
					conversation: state.conversation,
				)
				await MainActor.run {
					for msg in unreadMsgs {
						models.update(msg: msg)
					}
				}
			} catch {
				await showError(error)
			}
		}
	}
}
