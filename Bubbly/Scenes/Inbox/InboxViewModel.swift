//
//  InboxViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Foundation
import SwiftData
import Database
import Services
import XUI
import Core
import FirebaseAuth

@MainActor
@Observable
final class InboxViewModel: ErrorPresenter {

	var items = [InboxItem]()
	private let cancelBag = CancelBag()

	func task(currentUser: CurrentUserModel) async {
		observeInboxChanges(currentUser: currentUser)
		await fetch(currentUser: currentUser)

	}
	func ondisappear() {
		cancelBag.cancel()
	}

	private func observeInboxChanges(currentUser: CurrentUserModel) {
		cancelBag.cancel()
		NotificationCenter.default
			.publisher(for: .inboxChanges)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				Task {
					await self.fetch(currentUser: currentUser)
				}
			}.store(in: cancelBag)
	}

	private func fetch(currentUser: CurrentUserModel) async {
		do {
			let contactConversations = try await fetchContactConversations()
			let groupConversations = try await fetchGroupConversations()
			let conversations = contactConversations + groupConversations + [AnyConversation(.system(AI.contact))]
			let items = try await fetchInboxItems(conversations, currentUser: currentUser)
			await MainActor.run {
				self.items = items
			}
		} catch {
			await showError(error)
		}
	}

	@concurrent
	private func fetchInboxItems(_ conversations: [any ConversationRepresentable], currentUser: CurrentUserModel) async throws -> [InboxItem] {
		let items: [InboxItem?] = try await AsyncOrderedStream.mapOrdered(inputs: conversations) { conversation in
			if let lastMsgID = conversation.lastMsgID, let msg = try await Store.shared.msgStore.fetch(uid: lastMsgID) {
				let sender: any ContactRepresentable
				if msg.receiptType == .receive {
					sender = try await ContactRepo.getOrCreate(for: msg.senderID, refetch: false)
				} else {
					sender = currentUser
				}
				return InboxItem(
					conversation: conversation,
					msg: msg,
					sender: sender
				)
			}
			return nil
		}
//		var items = try await withThrowingTaskGroup(of: InboxItem?.self) { group in
//			conversations.forEach { conversation in
//				return group.addTask {
//					if let lastMsgID = conversation.lastMsgID, let msg = try await Store.shared.msgStore.fetch(uid: lastMsgID) {
//						print(msg)
//						let sender: any ContactRepresentable
//						if msg.receiptType == .receive {
//							sender = try await ContactRepo.getOrCreate(for: msg.senderID, refetch: false)
//						} else {
//							sender = currentUser
//						}
//						return InboxItem(
//							conversation: conversation,
//							msg: msg,
//							sender: sender
//						)
//					}
//					return nil
//				}
//			}
//			var items = [InboxItem]()
//			for try await item in group {
//				if let item {
//					items.append(item)
//				}
//			}
//			return items
//		}
//		if let msg = try await ConversationRepo.lastMsg(conID: AI.system.uid) {
//			let sender: any ContactRepresentable
//			if msg.receiptType == .receive {
//				sender = try await ContactRepo.getOrCreate(for: msg.senderID, refetch: false)
//			} else {
//				sender = currentUser
//			}
//			let item = InboxItem(
//				conversation: AnyConversation(.system(.system)),
//				msg: msg,
//				sender: sender
//			)
//			items.append(item)
//		}
		return items.compactMap { $0 }.sorted(by: { $0.msg.date > $1.msg.date })
	}

	private func fetchContactConversations() async throws -> [any ConversationRepresentable] {
		let lastMsgPredicate = #Predicate<PContact> { $0.lastMsgID != nil }
		var lastMsgDescriptor = FetchDescriptor<PContact>(predicate: lastMsgPredicate)
		lastMsgDescriptor.sortBy = [.init(\.uid, order: .forward)]
		return try await Store.shared.contactStore.fetch(lastMsgDescriptor).map { AnyConversation(.contact($0)) }
//
//		let contacts = ContactStore.shared.contacts.filter{ $0.lastMsgID != nil }
//		let items = try await withThrowingTaskGroup(of: InboxItem?.self) { group in
//			contacts.forEach { contact in
//				let conversation = AnyConversation(.contact(contact))
//				return group.addTask {
//					if let msgID = contact.lastMsgID, let msg = try await Store.shared.msgStore.fetch(uid: msgID) {
//						let sender: any ContactRepresentable3
//						if msg.receiptType == .receive {
//							sender = contact
//						} else {
//							sender = currentUser
//						}
//						return InboxItem(
//							conversation: conversation,
//							msg: msg,
//							sender: sender
//						)
//					}
//					return nil
//				}
//			}
//			var items = [InboxItem]()
//			for try await item in group {
//				if let item {
//					items.append(item)
//				}
//			}
//			return items
//		}
//		return items
	}
	private func fetchGroupConversations() async throws -> [any ConversationRepresentable] {
		let lastMsgPredicate = #Predicate<PGroup> { $0.lastMsgID != nil }
		var lastMsgDescriptor = FetchDescriptor<PGroup>(predicate: lastMsgPredicate)
		lastMsgDescriptor.sortBy = [.init(\.uid, order: .forward)]
		return try await Store.shared.groupStore.fetch(lastMsgDescriptor).map { AnyConversation(.group($0)) }
//
//		let items = try await withThrowingTaskGroup(of: InboxItem?.self) { group in
//			for contact in contacts {
//				group.addTask {
//					let conversation = AnyConversation(.group(contact))
//					guard
//						let msgID = conversation.lastMsgID,
//						let msg = try await Store.shared.msgStore.fetch(uid: msgID),
//						let sender: (any ContactRepresentable) = msg.isSender ? currentUser : try await Store.shared.contactStore.fetch(
//							uid: msg.senderID
//						)
//					else { return nil }
//
//					return InboxItem(conversation: conversation, msg: msg, sender: sender)
//				}
//			}
//			var collected: [InboxItem] = []
//			for try await chunk in group.compactMap({ $0 }) {
//				collected.append(chunk)
//			}
//			return collected
//		}
//		return items
	}
}
