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

@MainActor
protocol ChatViewUpdaterDelegate: AnyObject {
	var conversation: ConversationSnapshot { get set }
	var eventsManager: ChatViewEventsManager { get }
	var scrollManager: ChatScrollManager { get }
	var cellItems: [MsgCellViewModel] { get set }
}

@MainActor
final class ChatViewUpdater: ErrorPresenter {

	weak var delegate: ChatViewUpdaterDelegate?

	private var conversation: ConversationSnapshot? {
		get { delegate?.conversation }
		set {
			guard let newValue else { return }
			delegate?.conversation = newValue
		}
	}

	private var cellItems: [MsgCellViewModel] {
		get { delegate?.cellItems ?? [] }
		set { delegate?.cellItems = newValue }
	}
}

extension ChatViewUpdater {
	func insert(msgs: [MsgSnapshot]) {
		var newItems = cellItems
		msgs.forEach { each in
			if let existing = newItems.first(where: { $0.id == each.uid }) {
				existing.update(with: each)
			} else {
				let item = MsgCellViewModel(each)
				let index = newItems.insertionIndex(for: item, by: \.msg.date)
				newItems.insert(item, at: index)
			}
		}
		cellItems = newItems
	}
}

extension ChatViewUpdater: ChatDatasourceDelegate {

	func datasource(didRecieveError error: any Error) async {
		await showError(error)
	}

	func datasource(didReceive typingStatus: Database.AnyMsgData.TypingStatusPayload) async {
		delegate?.eventsManager.updateTypingStatus(typingStatus)
	}

	func datasource(didInsert snapshot: MsgSnapshot) async {
		if let existingModel = cellItems.first(where: { $0.msg.uid == snapshot.uid }) {
			existingModel.update(with: snapshot)
		} else {
			let newModel = MsgCellViewModel(snapshot)
			let index = cellItems.insertionIndex(for: newModel, by: \.msg.date)

			guard let delegate = self.delegate else { return }
			let scrollManager = delegate.scrollManager

			if scrollManager.canLoadMore == true {
				ToastPresenter.show(snapshot.text) { [weak self] in
					guard let self else { return }
					self.delegate?.scrollManager.scroll(to: .bottom(animated: true, duration: nil))
				}
			} else {
				if delegate.scrollManager.scrolledPosition == .atBottom {
					delegate.scrollManager.updateLoadingState(.appendingItem(newModel.id, index: index))
					cellItems.insert(newModel, at: index)
				} else {
					cellItems.insert(newModel, at: index)
					ToastPresenter.show(snapshot.text) { [weak self] in
						guard let self else { return }
						self.delegate?.scrollManager.scroll(to: .id(value: snapshot.uid, anchor: .center, animated: true, duration: nil))
					}
				}
			}
		}
	}

	func datasource(didReceiveMsg snapshot: MsgSnapshot) async {
		updateReceiveMsgs()
	}

	func datasource(didUpdate snapshot: MsgSnapshot, animated: Bool) async {
		guard let viewModel = cellItems.first(where: { $0.id == snapshot.id }) else { return }
		performUpdate(animated: animated) {
			viewModel.update(with: snapshot)
		}
	}

	func datasource(didRemove snapshot: MsgSnapshot, animated: Bool) async {
		guard let index = cellItems.firstIndex(where: { $0.id == snapshot.id }) else { return }
		performUpdate(animated: animated) { [weak self] in
			self?.cellItems.remove(at: index)
		}
	}

	func datasource(didReceive status: Database.AnyMsgData.SeenStatusPayload) async {
		await reloadConversation()
	}
}

// MARK: - Updates
extension ChatViewUpdater {

	func reloadConversation() async {
		guard let conID = conversation?.uid,
			  let newConversation = ConversationRepo.get(conID: conID) else {
			return
		}
		conversation = newConversation
	}

	func updateConversation() async {
		guard let conversation else {
			assertionFailure("Missing conversation")
			return
		}
		Task.detached { [self] in
			do {
				let updatedConversation = try await ConversationRepo.performUpdate(conversation)

				await MainActor.run {
					self.conversation = updatedConversation
					updateReceiveMsgs()
				}
			} catch {
				await showError(error)
			}
		}
	}
	func updateReceiveMsgs() {
		guard let lastMsg = cellItems.last?.msg,
			  lastMsg.receiptType == .receive,
			  lastMsg.incomingStatus.rawValue < MsgIncomingStatus.read.rawValue,
			  let conversation,
			  let currentUserId else {
			return
		}
		Task.detached { [self] in
			do {
				let msgs = try await ConversationRepo.updateReceiveMsgs(for: lastMsg.conID)

				await Socket.shared.send(
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

// MARK: - Animation
private extension ChatViewUpdater {
	func performUpdate(animated: Bool, _ action: @escaping () -> Void) {
		if animated {
			withAnimation(.snappy(duration: 0.25), action)
		} else {
			action()
		}
	}
}
