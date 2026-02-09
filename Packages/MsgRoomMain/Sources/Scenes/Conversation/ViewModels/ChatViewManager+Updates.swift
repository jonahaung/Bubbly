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
		if let existingModel = models.element(withID: msg.uid) {
			existingModel.update(with: msg)
		} else {
			if canResetDatasource {
				let toast = Toast(node: Text(msg.displayText).opaqueView()) {
					self.resetDatasource()
				}
				ToastPresenter.show(toast)
			} else {
				if scrollController.scrolledPosition.nearBottom {
					scrollController.setUpdateState(.appendingItem(msg.uid))
				} else {
					ToastPresenter.show {
						VStack(alignment: .leading, spacing: 4) {
							let image = Image(systemSymbol: .textBubble)
							Text("\(image) New Message")
								.font(
									.system(
										size:
										UIFont
											.preferredFont(forTextStyle: .headline).pointSize,
										weight: .medium
									)
								)
							Text(msg.displayText)
								.font(
									.system(
										size:
										UIFont
											.preferredFont(forTextStyle: .subheadline).pointSize,
										weight: .regular
									)
								)
						}
						.onTapGesture {
							self.scrollController
								.enqueueScroll(
									to:
									.layoutID(
										value: msg.uid,
										anchor: .bottom,
										animated: true,
										duration: 0.3
									)
								)
						}
					}
				}
				models.insert(msg: msg)
			}
		}
		await saveConversationChanges()
	}

	func datasource(didReceiveMsg msg: Message) async {
		await saveConversationChanges()
	}

	func datasource(didUpdate snapshot: Message, animated: Bool) async {
		models.update(msg: snapshot)
	}

	func datasource(didRemove snapshot: Message, animated: Bool) async {
		scrollController.setDefaultAnimation(.smooth)
		models.remove(msg: snapshot)
	}

	func datasource(didReceive status: Database.AnyMsgData.SeenStatusPayload) async {
		conversation.properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
		conversation.properties.seenMembers.append(status.seenMember)
		layoutIfNeeded()
	}
}

extension ChatViewManager {
	func reloadData(with msgs: [Message], forceReset: Bool) {
		models.set(msgs: msgs, forceReset: forceReset)
		presentation.showContactInfo = {
			guard let firstMsgID = conversationConfig.firstMsgID else { return true }
			return msgs.contains(where: { $0.id == firstMsgID })
		}()
	}

	func reloadConversation() async throws {
		conversation = try await conversation.reload(refetch: false)
	}

	func updateReceiveMsgs() {
		guard
			let lastMsg = models.msgs().last(
				where: {
					$0.receiptType == .receive
				}
			),
			lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
			let currentUserId
		else {
			return
		}
		Task.detached { [self] in
			do {
				let msgs = try await ConversationRepo.updateReceiveMsgs(
					for: lastMsg.conID,
					currentUserID: currentUserId
				)
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
						if let model = self.models.element(withID: msg.uid) {
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
