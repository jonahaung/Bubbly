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
		await updateReceiveMsgs()
		do {
			try await conversation.saveChanges()
		} catch {
			await showError(error)
		}
	}
	func datasource(didRecieveError: any Error) async {
		await showError(didRecieveError)
	}

	func datasource(didReceive typingStatus: Database.AnyMsgData.TypingStatusPayload) async {
		eventsManager.updateTypingStatus(typingStatus)
	}

	func datasource(didInsert msg: Message) async {
		if let existingModel = data.element(withID: msg.uid) {
			existingModel.update(with: msg)
		} else {
			if canResetDatasource {
				ToastPresenter.show(msg.text) { [weak self] in
					guard let self else { return }
					resetDatasource()
				}
			} else {
				let newModel = MsgCellViewModel(msg)
				let index = data.insertionIndex(for: newModel, by: \.msg.date)
				let previousItem = data[safe: index - 1]
				let nextItem = data[safe: index + 1]

				if scrollManager.scrolledPosition.nearBottom {
					scrollManager.updateLoadingState(.appendingItem(msg.uid))
				} else {
					let msgID = msg.uid
					ToastPresenter.show(msg.text) { [weak self] in
						guard let self else { return }
						scrollManager.scroll(to: .id(value: msgID, anchor: .bottom))
					}
				}

				let layout = bubbleFactory.msgCellLayout(
					for: msg,
					previous: previousItem?.msg,
					next: nextItem?.msg
				)
				newModel.update(layout: layout)

				data.insert(newModel, at: index)
				if let previousItem {
					previousItem.update(layout: msgCellLayoutFor(previousItem.msg, cellItems: data.array))
				}
				if let nextItem {
					nextItem.update(layout: msgCellLayoutFor(nextItem.msg, cellItems: data.array))
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
		data.update(snapshot) { [self] msg, prev, next in
			bubbleFactory.msgCellLayout(for: msg, previous: prev, next: next)
		}
	}

	func datasource(didRemove snapshot: Message, animated: Bool) async {
		data.remove(snapshot) { [self] msg, prev, next in
			bubbleFactory.msgCellLayout(for: msg, previous: prev, next: next)
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
		var newItems = forceReset ? [] : data.array
		for msg in msgs {
			if let existing = data.element(withID: msg.uid) {
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
		eventsManager.showContactInfo = {
			guard let firstMsgID = config.firstMsgID else { return true }
			return newItems.contains(where: { $0.id == firstMsgID })
		}()
		for item in newItems {
			if item.layout.isEmpty {
				let layout = msgCellLayoutFor(item.msg, cellItems: newItems)
				item.update(layout: layout)
			}
		}
		data = .init(newItems)
	}

	func reloadConversation() async throws {
		conversation = try await conversation.reload(refetch: false)
	}

	func updateReceiveMsgs() {
		guard let lastMsg = data.array.last(where: { $0.isSender == false })?.msg,
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
						if let model = self.data.element(withID: msg.uid) {
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
