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

	func datasource(didRecieveError error: any Error) async {
		await showError(error)
	}

	func datasource(didReceive typingStatus: AnyMsgData.TypingStatusPayload) async {
		presentation.updateTypingStatus(typingStatus)
	}

	func datasource(didInsert msg: Message) async {
		if let existingModel = models.element(withID: msg.uid) {
			existingModel.update(with: msg)
		} else {
			if scrollController.state.geometry.isNear(.bottom) {
				scrollController.state.updateState.update(to: .appendingItem(msg.uid))
			} else {
				let toast = Toast(
					node: Text(msg.displayText).opaqueView(),
					allowsBackgroundTap: false
				) {
					if self.canResetDatasource {
						self.resetDatasource()
					} else {
						self.scrollController
							.performScroll(to: .id(msg.uid, animation: .interpolatingSpring))
					}
				}
				ToastPresenter.show(toast)
			}
			models.insert(msg: msg)
			layoutIfNeeded()
		}

		await saveConversationChanges()
	}

	func datasource(didReceiveMsg _: Message) async {
		await saveConversationChanges()
	}

	func datasource(didUpdate snapshot: Message, animated _: Bool) async {
		models.update(msg: snapshot)
	}

	func datasource(didRemove snapshot: Message, animated _: Bool) async {
		models.remove(msg: snapshot)
		layoutIfNeeded()
	}

	func datasource(didReceive status: AnyMsgData.SeenStatusPayload) async {
		conversation.properties.seenMembers.removeAll(where: { $0.uid == status.seenMember.uid })
		conversation.properties.seenMembers.append(status.seenMember)
		await saveConversationChanges()
		layoutIfNeeded()
	}
}

//private extension ChatViewManager {
//	func enqueueDatasourceMutation(_ mutation: DatasourceMutation) {
//		pendingDatasourceMutations.append(mutation)
//		guard datasourceFlushTask == nil else { return }
//		datasourceFlushTask = Task { [weak self] in
//			try? await Task.sleep(for: .milliseconds(30))
//			self?.flushDatasourceMutations()
//		}
//	}
//
//	func flushDatasourceMutations() {
//		datasourceFlushTask = nil
//		guard !pendingDatasourceMutations.isEmpty else { return }
//		let mutations = pendingDatasourceMutations
//		pendingDatasourceMutations.removeAll(keepingCapacity: true)
//		var shouldLayout = false
//		var transaction = Transaction()
//		transaction.disablesAnimations = true
//		withTransaction(transaction) {
//			for mutation in mutations {
//				switch mutation {
//				case let .insert(msg):
//					if let existingModel = models.element(withID: msg.uid) {
//						existingModel.update(with: msg)
//						shouldLayout = true
//					} else if canResetDatasource {
//						let toast = Toast(
//							node: Text(msg.displayText).opaqueView(),
//							allowsBackgroundTap: false
//						) {
//							self.resetDatasource()
//						}
//						ToastPresenter.show(toast)
//					} else {
//						if scrollController.state.geometry.scrolledPosition.nearBottom {
//							scrollController.state.updateState = .appendingItem(msg.uid)
//						}
//						models.insert(msg: msg)
//						shouldLayout = true
//					}
//				case let .update(msg):
//					models.update(msg: msg)
//					shouldLayout = true
//				case let .remove(msg):
//					models.remove(msg: msg)
//					shouldLayout = true
//				}
//			}
//		}
//		if shouldLayout {
//			layoutIfNeeded()
//
//		}
//		updateReceiveMsgs()
//	}
//}

extension ChatViewManager {
	func reloadData(with msgs: [Message], forceReset: Bool) {
		models.set(msgs: msgs, forceReset: forceReset)
//		presentation.showContactInfo = {
//			guard let firstMsgID = conversationConfig.firstMsgID else { return true }
//			return msgs.contains(where: { $0.id == firstMsgID })
//		}()
		layoutIfNeeded()
	}

	func reloadConversation() async throws {
		conversation = try await conversation.reload(refetch: false)
	}

	func updateReceiveMsgs() {
		guard
			let lastMsg = models.msgs().last(where: { $0.receiptType == .receive }),
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
				}
			} catch {
				await showError(error)
			}
		}
	}
}
