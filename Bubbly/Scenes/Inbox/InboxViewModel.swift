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
final class InboxViewModel {

	var items = [InboxItem]()
	private let cancelBag = CancelBag()

	init() {
		NotificationCenter.default
			.publisher(for: .inboxChanges)
			.receive(on: RunLoop.main)
			.sink { [weak self] _ in
				guard let self else { return }
				Task {
					await self.fetch()
				}
			}.store(in: cancelBag)
	}

	func fetch() async {
		guard let user = Auth.auth().currentUser else { return }
		let predicate = #Predicate<PContact> { $0.lastMsgID != nil }
		var descriptor = FetchDescriptor<PContact>(predicate: predicate)
		descriptor.sortBy = [.init(\.lastMsgID, order: .forward)]

		do {
			let contacts = try await Store.shared.contactStore.fetch(descriptor)
			let items = try await withThrowingTaskGroup(of: InboxItem?.self) { group in
				contacts.forEach { contact in
					let conversation = AnyConversation(.contact(contact))
					return group.addTask {
						if let msg = try await ConversationRepo.lastMsg(
							conID: conversation.uid
						) {
							let sender: Contact
							if msg.receiptType == .receive {
								sender = contact
							} else {
								sender = user.snapshot()
							}
							return InboxItem(
								conversation: conversation,
								msg: msg,
								sender: sender
							)
						}
						return nil
					}
				}
				var items = [InboxItem]()
				for try await item in group {
					if let item {
						items.append(item)
					}
				}
				return items.sorted(by: { $0.msg.date > $1.msg.date })
			}
			Task { @MainActor in
				self.items = items
			}
		} catch {
			Log(error)
		}
	}
}
