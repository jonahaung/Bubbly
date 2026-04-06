
//
//  ChatViewManager+DataObserver.swift
//  Conversation
//
//  Created by Aung Ko Min on 2/4/26.
//

import Database
import SwiftUI
import XUI

extension ChatManager: ChatDataObserverDelegate {
	@concurrent func saveConversationChanges() async {
		do {
			let properties = await state.properties
			try await Store.shared
				.conversationPropertiesStore?
				.updateAndSave(uid: conversationConfig.conID) { model in
					model.update(from: properties)
				}
		} catch {
			await showError(error)
		}
	}

	func dataObserver(didRecieveError error: any Error) async {
		await showError(error)
	}

	func dataObserver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async {
		presentation.send(.typing(typingStatus))
	}

	func dataObserver(didInsert msg: Message) async {
		if models.contains(withID: msg.uid) {
			models.update(msg: msg)
			return
		}
		if scrollController.isNear(.bottom) {
			scrollController.updateStateUpdate(to: .appendingItem(msg.uid))
			models.insert(msg: msg)
			layoutIfNeeded()
		} else {
			if scrollCoordinator(scrollController, shouldPaginateAt: .bottom) {
				let toast = Toast(
					node: Text(msg.displayText).opaqueView(),
					allowsBackgroundTap: false,
				) { [weak self] in
					guard let self else {
						return
					}
					ToastPresenter.shared.dismiss()
					scrollTo(msgID: msg.uid)
				}
				ToastPresenter.show(toast)

			} else {
				models.insert(msg: msg)
				layoutIfNeeded()
				let toast = Toast(
					node: Text(msg.displayText).opaqueView(),
					allowsBackgroundTap: false,
				) { [weak self] in
					guard let self else {
						return
					}
					ToastPresenter.shared.dismiss()
					scrollTo(msgID: msg.uid)
				}
				ToastPresenter.show(toast)
			}
		}
	}

	func dataObserver(didReceiveMsg _: Message) async {
		updateReceiveMsgs()
	}

	func dataObserver(didUpdate msg: Message, animated _: Bool) async {
		models.update(msg: msg)
		layoutIfNeeded()
	}

	func dataObserver(didRemove msg: Message, animated _: Bool) async {
		models.remove(msg: msg)
		withTransaction(.withAnimation(.anticipate)) {
			layoutIfNeeded()
		}
	}

	func dataObserver(didReceive status: AnyMsgData.SeenStatusPayload) async {
		var properties = state.properties
		properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
		properties.seenMembers.append(status.seenMember)
		state.properties = properties
		await saveConversationChanges()
		layoutIfNeeded()
	}
}
