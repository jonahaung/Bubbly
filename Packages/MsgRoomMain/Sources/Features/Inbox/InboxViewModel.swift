import Core
import Database
import FirebaseAuth
import Foundation
import Services
import SwiftData
import XUI

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
			let conversations = try await fetchContactConversations()
			let items = try await fetchInboxItems(conversations, currentUser: currentUser)
			await MainActor.run {
				self.items = items
			}
		} catch {
			await showError(error)
		}
	}

	@concurrent
	private func fetchInboxItems(_ conversations: [Conversation],
	                             currentUser: CurrentUserModel) async throws -> [InboxItem]
	{
		let items: [InboxItem?] = try await AsyncOrderedStream
			.mapOrdered(inputs: conversations) { conversation in
				if let msg = try await ConversationRepo.lastMsg(
					conID: conversation.uid
				) {
					let sender: any ContactRepresentableSendable =
						if msg.receiptType == .receive {
							try await ContactRepo.getOrCreate(for: msg.senderID, refetch: false)
						} else {
							currentUser
						}
					let unreadMsgsCount = try await ConversationRepo.countUnreadMsgs(
						conID: conversation.uid,
						currentUserID: currentUser.uid
					)
					return InboxItem(
						conversation: conversation,
						msg: msg,
						sender: sender,
						unreadMsgsCount: unreadMsgsCount
					)
				}
				return nil
			}
		return items.compactMap(\.self).sorted(by: { $0.msg.date > $1.msg.date })
	}

	private func fetchContactConversations() async throws -> [Conversation] {
//		let predicate = #Predicate<PConversationProperties> { $0.lastMsgID != nil }
		var descriptor = FetchDescriptor<PConversationProperties>()
		descriptor.sortBy = [.init(\.uid, order: .forward)]
		let properties = try await Store.shared.conversationPropertiesStore?.fetch(descriptor)

		return try await withThrowingTaskGroup(of: Conversation.self) { group in
			properties?.forEach { property in
				let conID = property.uid
				return group.addTask {
					try await ConversationRepo.getOrCreate(for: conID, refetch: false)
				}
			}
			var items = [Conversation]()
			for try await item in group {
				items.append(item)
			}
			return items
		}
	}
}
