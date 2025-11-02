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
import FirebaseAuth
import XUI

@MainActor
@Observable
public final class ContactStore: ErrorPresenter {
	public static var shared: ContactStore {
		get { sharedLock.value }
		set { sharedLock.value = newValue}
	}
	private static let sharedLock = Mutex(ContactStore())
	private init() {}

	public var contacts = [Contact]()
	public var groups = [Group]()

	public func delete(uid: String) async throws {
		if let indext = contacts.firstIndex(where: { $0.uid == uid }) {
			try await Store.shared.contactStore
				.delete(uid: uid)
			contacts.remove(at: indext)
		}
	}

	public func contact(for uid: String) -> Contact? {
		contacts.first(where: { $0.uid == uid })
	}

	@concurrent
	public func fetchData() async throws {
		let contacts = try await Store.shared.contactStore.fetchAll()
		let groups = try await Store.shared.groupStore.fetchAll()
		Task { @MainActor in
			self.contacts = contacts
			self.groups = groups
		}
	}

	public func refresh() async throws {
		contacts.removeAll()
		try await Task.sleep(seconds: 2)
		try await fetchData()
	}
}

public extension ContactStore {
	@concurrent func syncGroups() async throws {
		guard let currentUserId else {
			fatalError("Missing current user ID")
		}
		let groups: [Group] = try await FirestoreRepo.getModels(for: currentUserId, collection: .groups, field: .members)

		let store = Store.shared.groupStore

		try await withThrowingTaskGroup(of: Void.self) { taskGroup in
			for group in groups {
				taskGroup.addTask {
					if try await store.exists(uid: group.uid) == false {
						try await store.insert(group)
					} else {
						try await store.updateAndSave(uid: group.uid) { model in
							model.update(with: group)
						}
					}
					try await ContactRepo.getOrCreate(for: group.members, refatch: false)
				}
			}
			try await taskGroup.waitForAll()
		}
		try await fetchData()
	}
	@concurrent func syncContacts() async throws {
		try await PhoneContactsService.shared.syncContacts()
		try await fetchData()
	}
}
