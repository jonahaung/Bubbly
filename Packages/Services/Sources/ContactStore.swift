//
//  ContactStore.swift
//  Database
//
//  Created by Aung Ko Min on 15/8/25.
//

import Foundation
import Core
import Database
import SwiftData
import FirebaseFirestore

@Observable
public final class ContactStore: Sendable, ErrorPresenter {

	public static let shared = ContactStore()
	@MainActor
	public var contacts = [ContactSnapshot]()
	@MainActor
	public var conversationGroups = [ConversationSnapshot]()
	@MainActor
	public var availableContacts: [ContactSnapshot] {
		contacts.filter { $0.isChatAvailable && $0.uid != currentUserId }
	}

	private init() {
		Task.detached(priority: .background) { [weak self] in
			try? await self?.fetchData()
		}
	}

	public func fetchData() async throws {
		try await fetchGroups()
		try await fetchContacts()
	}

	public func refreshData() async throws {
		try await Task.sleep(seconds: 1)
		try await fetchData()
	}

	public func fetchContacts() async throws {
		let contacts = try await Store.shared.contactStore.fetch()
		await MainActor.run {
			self.contacts = contacts
		}
	}

	private func fetchGroups() async throws {
		let groupTypeRawValue = ConversationType.group.rawValue
		let groupPredicate = #Predicate<PConversation> {
			$0.type == groupTypeRawValue
		}
		let groupDescriptor = FetchDescriptor<PConversation>(
			predicate: groupPredicate,
			sortBy: [.init(\.createdDate, order: .forward)]
		)
		let groups = try await Store.shared.conversationStore.fetch(
			groupDescriptor
		)
		await MainActor.run {
			self.conversationGroups = groups
		}
	}

	public func syncGroups() async throws {
		guard let currentUserId = GroupAppStorage.shared.string(for: .auth(.currentUserID)) else {
			return
		}
		let reference = Firestore.firestore().collection("groups").whereField(
			"members",
			arrayContains: currentUserId
		)
		let groups: [Group] = try await FirestoreRepo.fetch(
			query: reference
		)
		let remoteGroups = groups.map { ConversationSnapshot(group: $0) }
		let store = Store.shared.conversationStore
		await withThrowingTaskGroup(of: Void.self) { group in
			remoteGroups.forEach { each in
				return group.addTask {
					if try await store.isExisted(uid: each.uid) == false {
						try await Store.shared.conversationStore.insert(each)
					} else {
						try await store
							.updateAndSave(uid: each.uid) { model in
								model.update(with: each)
							}
					}
				}
			}
		}
		try await fetchData()
	}

	public func syncContacts() async throws {
		try Store.shared.contactStore.modelExecutor.modelContext.delete(model: PContact.self)
		let contacts = try await PhoneContactsService.shared.syncContacts()
		await MainActor.run {
			self.contacts = contacts
		}
	}

	@MainActor
	public func delete(uid: String) async throws {
		if let indext = contacts.firstIndex(where: { $0.uid == uid }) {
			try await Store.shared.contactStore
				.delete(uid: uid)
			contacts.remove(at: indext)
		}
	}

	@MainActor
	public func contact(for uid: String) -> ContactSnapshot? {
		contacts.first(where: { $0.uid == uid })
	}
}
