//
//  ChatViewManager+Updates.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/8/25.
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
			try await conversation.saveChanges()
		} catch {
			await showError(error)
		}
	}
	func datasource(didRecieveError: any Error) async {
		await showError(didRecieveError)
	}

	func datasource(didReceive typingStatus: Database.AnyMsgData.TypingStatusPayload) async {
		presentation.updateTypingStatus(typingStatus)
	}

	func datasource(didInsert msg: Message) async {
		if let existingModel = messageItems.element(withID: msg.uid) {
			existingModel.update(with: msg)
		} else {
			if canResetDatasource {
				ToastPresenter.show(msg.displayText) { [weak self] in
					guard let self else { return }
					resetDatasource()
				}
			} else {
				let newModel = MsgCellViewModel(msg)
				let index = messageItems.insertionIndex(for: newModel, by: \.msg.date)
				let previousItem = messageItems[safe: index - 1]
				let nextItem = messageItems[safe: index + 1]

				if scrollController.currentScrolledPosition.nearBottom {
					scrollController.setUpdateState(.appendingItem(msg.uid))
				} else {
					let msgID = msg.uid
					ToastPresenter.show(msg.displayText) { [weak self] in
						guard let self else { return }
						scrollController.enqueueScroll(to: .id(value: msgID, anchor: .bottom))
					}
				}

				let layout = bubbleLayout.msgCellLayout(
					for: msg,
					previous: previousItem?.msg,
					next: nextItem?.msg
				)
				newModel.update(layout: layout)

				messageItems.insert(newModel, at: index)
				if let previousItem {
					previousItem
						.update(layout: msgCellLayoutFor(previousItem.msg, cellItems: messageItems.array))
				}
				if let nextItem {
					nextItem.update(layout: msgCellLayoutFor(nextItem.msg, cellItems: messageItems.array))
				}
				layoutIfNeeded()
			}
		}
		await saveConversationChanges()
	}

	func datasource(didReceiveMsg msg: Message) async {
		await saveConversationChanges()
	}

	func datasource(didUpdate snapshot: Message, animated: Bool) async {
		messageItems.update(snapshot) { [self] msg, prev, next in
			bubbleLayout.msgCellLayout(for: msg, previous: prev, next: next)
		}
	}

	func datasource(didRemove snapshot: Message, animated: Bool) async {
		scrollController.setDefaultAnimation(.interactiveSpring(duration: 0.3))
		messageItems.remove(snapshot) { [self] msg, prev, next in
			self.layoutIfNeeded()
			return bubbleLayout.msgCellLayout(for: msg, previous: prev, next: next)
		}
	}

	func datasource(didReceive status: Database.AnyMsgData.SeenStatusPayload) async {
		conversation.properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
		conversation.properties.seenMembers.append(status.seenMember)
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func reloadData(with msgs: [Message], forceReset: Bool) {
		var newItems = forceReset ? [] : messageItems.array
		for msg in msgs {
			if let existing = messageItems.element(withID: msg.uid) {
				existing.update(with: msg)
				if forceReset {
					newItems.append(existing)
				}
			} else {
				let item = MsgCellViewModel(msg)
				let index = newItems.insertionIndex(for: item, by: \.msg.date)
				newItems.insert(item, at: index)
			}
		}
		presentation.showContactInfo = {
			guard let firstMsgID = conversationConfig.firstMsgID else { return true }
			return newItems.contains(where: { $0.id == firstMsgID })
		}()
		for item in newItems {
			if item.layout.isEmpty {
				let layout = msgCellLayoutFor(item.msg, cellItems: newItems)
				item.update(layout: layout)
			}
		}
		messageItems = .init(newItems)
	}

	func reloadConversation() async throws {
		conversation = try await conversation.reload(refetch: false)
	}

	func updateReceiveMsgs() {
		guard let lastMsg = messageItems.array.last(where: { $0.msg.receiptType == .receive })?.msg,
			  lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
			  let currentUserId
		else {
			return
		}
		Task.detached { [self] in
			do {
				let msgs = try await ConversationRepo.updateReceiveMsgs(for: lastMsg.conID)
				try await Socket.shared.send(
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
						if let model = self.messageItems.element(withID: msg.uid) {
							model.update(with: msg)
						}
					}
				}
			} catch {
				await showError(error)
			}
		}
	}
}
