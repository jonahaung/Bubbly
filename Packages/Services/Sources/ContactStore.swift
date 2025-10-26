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
import FirebaseAuth
import XUI

@Observable
public final class ContactStore: Sendable, ErrorPresenter {

	public static let shared = ContactStore()
	@MainActor
	public var contacts = [Contact]()
	@MainActor
	public var conversationGroups = [Database.Group]()
	@MainActor
	public var availableContacts: [Contact] {
		contacts.filter { $0.isChatAvailable && $0.uid != currentUserId }
	}

	private init() {
		Task.detached(priority: .background) { [weak self] in
			try? await self?.fetchData()
		}
	}
	@concurrent
	public func fetchData() async throws {
		try await fetchGroups()
		try await fetchContacts()
	}
	@concurrent
	public func refreshData() async throws {
		try await Task.sleep(seconds: 1)
		try await fetchData()
	}
	@concurrent
	public func fetchContacts() async throws {
		let contacts = try await Store.shared.contactStore.fetchAll()
		await MainActor.run {
			self.contacts = contacts
		}
	}

	@concurrent
	public func fetchGroups() async throws {
		let groups = try await Store.shared.groupStore.fetchAll()
		await MainActor.run {
			self.conversationGroups = groups
		}
	}

	@concurrent
	public func syncGroups() async throws {
		guard let currentUserId = Auth.auth().currentUser?.uid else {
			fatalError("Missing current user ID")
		}

		let reference = Firestore.firestore()
			.collection("groups")
			.whereField("members", arrayContains: currentUserId)

		let groups: [Group] = try await FirestoreRepo.fetch(query: reference)
		let store = Store.shared.groupStore

		// Replace parallelEach with a concurrent task group
		try await withThrowingTaskGroup(of: Void.self) { group in
			for groupItem in groups {
				group.addTask {
					if try await store.exists(uid: groupItem.uid) == false {
						try await store.insert(groupItem)
					} else {
						try await store.updateAndSave(uid: groupItem.uid) { model in
							model.update(with: groupItem)
						}
					}
				}
			}
			try await group.waitForAll()
		}

		// Fetch additional data after syncing
		try await fetchData()
	}
	@concurrent
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
	public func contact(for uid: String) -> Contact? {
		contacts.first(where: { $0.uid == uid })
	}
}
