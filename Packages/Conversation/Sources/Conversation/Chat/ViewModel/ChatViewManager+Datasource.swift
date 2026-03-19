//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension ChatViewManager: ChatDatasourceDelegate {
	@concurrent func saveConversationChanges() async {
		do {
			await updateReceiveMsgs()
			//			try await conversation.saveChanges()
			let properties = await state.properties
			try await Store.shared.conversationPropertiesStore?
				.updateAndSave(uid: conversationConfig.conID) { model in
					model.update(from: properties)
				}
		} catch {
			await showError(error)
		}
	}

	func datasource(didRecieveError error: any Error) async {
		await showError(error)
	}

	func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async {
		presentation.send(.typing(typingStatus))
	}

	func datasource(didInsert msg: Message) async {
		if let existingModel = models.element(withID: msg.uid) {
			existingModel.update(with: msg)
		} else {
			if scrollController.isNear(.bottom) {
				scrollController.updateStateUpdate(to: .appendingItem(msg.uid))
				models.insert(msg: msg)
				layoutIfNeeded()
			} else {
				if canResetDatasource {
					let toast = Toast(
						node: Text(msg.displayText).opaqueView(),
						allowsBackgroundTap: false
					) {
						self.resetData()
					}
					ToastPresenter.show(toast)
					
				} else {
					models.insert(msg: msg)
					layoutIfNeeded()
					let toast = Toast(
						node: Text(msg.displayText).opaqueView(),
						allowsBackgroundTap: false
					) {
						self.scrollController
							.enqueueScroll(to: .id(msg.uid, properties: .animated(.easeOut)))
					}
					ToastPresenter.show(toast)
				}
			}
		}
	}

	func datasource(didReceiveMsg msg: Message) async {
		updateReceiveMsgs()
	}

	func datasource(didUpdate snapshot: Message, animated _: Bool) async {
		models.update(msg: snapshot)
		layoutIfNeeded()
	}

	func datasource(didRemove snapshot: Message, animated _: Bool) async {
		models.remove(msg: snapshot)
		layoutIfNeeded()
	}

	func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async {
		var properties = state.properties
		properties.seenMembers.removeAll()
		properties.seenMembers.append(status.seenMember)
		state.properties = properties
		await saveConversationChanges()
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func reloadConversation(refetch: Bool) async throws {
		var state = self.state
		state.properties =
			try await ConversationPropertiesRepo
			.getOrCreate(for: conversationConfig.conID)
		state.conversation = try await conversation.reload(refetch: refetch)
		state.theme = .init(state.properties.theme)
		self.state = state
		layoutIfNeeded()
	}

	func updateReceiveMsgs() {
		guard
			let lastMsg = models.msgs().last(where: { $0.receiptType == .receive }),
			lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
			let currentUserId
		else {
			return
		}

		serialQueue.addOperation { [self] in
			do {
				let msgs = try await ConversationRepo.updateReceiveMsgs(
					for: lastMsg.conID,
					currentUserID: currentUserId
				)
				try await Socket.send(
					.seenStatus(
						status: .init(
							msgID: lastMsg.uid,
							userID: currentUserId,
							conID: lastMsg.conID
						)
					),
					conversation: conversation
				)
				await MainActor.run {
					for msg in msgs {
						if let model = self.models.element(withID: msg.uid) {
							model.update(with: msg)
						}
					}
					layoutIfNeeded()
				}
			} catch {
				await showError(error)
			}
		}
	}
}
