//
//  File.swift
//  Conversation
//
//  Created by Aung Ko Min on 8/4/26.
//


import Database
import SwiftUI
import XUI

extension ChatManager: ChatDataReceiverDelegate {

	func dataObserver(didRecieveError error: any Error) {
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			await showError(error)
		}
	}

	func dataObserver(didReceive typingStatus: AnyMsgData.TypingStatusPayload) {
		serialQueue.addOperation { @MainActor [weak self] in
			guard let self else {
				return
			}
			presentation.send(.typing(typingStatus))
		}
	}

	func dataObserver(didInsert msg: Message) {
		if models.contains(withID: msg.uid) {
			serialQueue.addOperation { @MainActor [weak self] in
				guard let self else {
					return
				}
				models.update(msg: msg)
			}
			return
		}
		if scrollController.isNear(.bottom) {
			serialQueue.addOperation { @MainActor [weak self] in
				guard let self else {
					return
				}
				scrollController.updateStateUpdate(to: .appendingItem(msg.uid))
				models.insert(msg: msg)
				layoutIfNeeded()
			}
		} else {
			if scrollCoordinator(scrollController, shouldPaginateAt: .bottom) {
				serialQueue.addOperation { @MainActor [weak self] in
					guard let self else {
						return
					}
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
			} else {
				serialQueue.addBarrierOperation { @MainActor [weak self] in
					guard let self else {
						return
					}
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

				serialQueue.addOperation { @MainActor [weak self] in
					guard let self else {
						return
					}
					models.insert(msg: msg)
					layoutIfNeeded()
				}
			}
		}
	}

	func dataObserver(didReceiveMsg _: Message) {
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			try await updateReceiveMsgs()
		}
	}

	func dataObserver(didUpdate msg: Message, animated _: Bool) {
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			models.update(msg: msg)
		}
	}

	func dataObserver(didRemove msg: Message, animated _: Bool) {
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			models.remove(msg: msg)
		}
		serialQueue.addBarrierOperation { @MainActor [weak self] in
			guard let self else {
				return
			}
			layoutIfNeeded()
		}
	}

	func dataObserver(didReceive status: AnyMsgData.SeenStatusPayload) {
		serialQueue.addOperation { [weak self] in
			guard let self else {
				return
			}
			try await reloadConversation(refetch: false)
		}
		serialQueue.addBarrierOperation { [weak self] in
			guard let self else {
				return
			}
			try await updateSendMsgs(status: status)
		}
	}
}
