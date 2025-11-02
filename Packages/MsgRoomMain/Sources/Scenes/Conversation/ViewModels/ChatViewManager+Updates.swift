//
//  ChatViewUpdator.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 26/8/25.
//

import SwiftUI
import Services
import Database
import XUI

extension ChatViewManager: ChatDatasourceDelegate {
	func datasource(didRecieveError: any Error) {
		Task {
			await showError(didRecieveError)
		}
	}

	func datasource(didReceive typingStatus: Database.AnyMsgData.TypingStatusPayload) {
		eventsManager.updateTypingStatus(typingStatus)
	}

	func datasource(didInsert snapshot: Message) {
		conversation.lastMsgID = snapshot.uid
		if let existingModel = cellItems.first(where: { $0.msg.uid == snapshot.uid }) {
			existingModel.update(with: snapshot)
		} else {
			if canLoadMore {
				ToastPresenter.show(snapshot.text) { [weak self] in
					guard let self else { return }
					self.scrollManager.scroll(to: .bottom())
				}
			} else {
				scrollManager.updateLoadingState(.appendingItem(snapshot.uid))
				let newModel = MsgCellViewModel(snapshot)
				let index = cellItems.insertionIndex(for: newModel, by: \.msg.date)
				let previousItem = cellItems[safe: index-1]
				let nextItem = cellItems[safe: index+1]
				let layout = bubbleFactory.msgCellLayout(for: snapshot, previous: previousItem?.msg, next: nextItem?.msg)
				newModel.update(layout: layout)
				cellItems.insert(newModel, at: index)
				if let previousItem {
					previousItem.update(layout: msgCellLayoutFor(previousItem.msg, cellItems: cellItems))
				}
				if scrollManager.scrolledPosition != .atBottom {
					ToastPresenter.show(snapshot.text) { [weak self] in
						guard let self else { return }
						self.scrollManager.scroll(to: .id(value: snapshot.uid, anchor: .center))
					}
				}
			}
		}
		Task.detached { [weak self] in
			guard let self else { return }
			try? await self.conversation.saveChanges()
		}
	}

	func datasource(didReceiveMsg snapshot: Message) {
		updateReceiveMsgs()
		conversation.lastMsgID = snapshot.uid
		Task.detached { [weak self] in
			guard let self else { return }
			try? await self.conversation.saveChanges()
		}
	}

	func datasource(didUpdate snapshot: Message, animated: Bool) {
		guard let viewModel = cellItems.first(where: { $0.id == snapshot.uid }) else { return }
		withTransaction(animated ? .withAnimation : .withoutAnimation) {
			viewModel.update(with: snapshot)
		}
	}

	func datasource(didRemove snapshot: Message, animated: Bool) {
		withTransaction(animated ? .withAnimation : .withoutAnimation) {
			cellItems.removeAll { $0.id == snapshot.uid }
		}
	}

	func datasource(didReceive status: Database.AnyMsgData.SeenStatusPayload) {
		Task {
			try? await reloadConversation()
		}
	}
}

// MARK: - Updates
extension ChatViewManager {
	func performUpdate(to items: [MsgCellViewModel], animated: Bool = false) {
		items.forEach { cellItem in
			if cellItem.layout.isEmpty {
				let layout = msgCellLayoutFor(cellItem.msg, cellItems: items)
				cellItem.update(layout: layout)
			}
		}
		if animated {
			withTransaction(.withAnimation) {
				cellItems = items
			}
		} else {
			cellItems = items
		}
	}
	func createCellItems(for msgs: [Message], forceReset: Bool) -> [MsgCellViewModel] {
		var newItems = forceReset ? [] : cellItems
		msgs.forEach { msg in
			if let existing = cellItems.first(where: { $0.id == msg.uid }) {
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
		return newItems
	}
	func reloadConversation() async throws {
		conversation = try await conversation.reload(refetch: false)
	}
	func updateReceiveMsgs() {
		guard let lastMsg = cellItems.last?.msg,
			  lastMsg.receiptType == .receive,
			  lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
			  let currentUserId else {
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
						if let model = self.cellItems.first(where: { $0.msg.uid == msg.uid }) {
							model.update(with: msg)
						}
					}
				}
			} catch {
				await self.showError(error)
			}
		}
	}
}
