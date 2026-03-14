//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Observation
import Services
import XUI

@MainActor
@Observable
final class ContactsViewModel: ErrorPresenter {

	var isLoading: Bool = false
	var searchText: String = ""
	private var contacts = [Contact]()
	var groups = [Group]()

	var displayContacts: [Contact] {
		if searchText.isEmpty {
			return contacts
		}
		return contacts.filter { $0.name.lowercased().contains(searchText.lowercased()) }
	}
	init() {}

	func task() async {
		loading(true)
		do {
			contacts = try await Store.shared.contactStore?.fetchAll() ?? []
			groups = try await Store.shared.groupStore?.fetchAll() ?? []
		} catch {
			await showError(error)
		}
		loading(false)
	}

	func refresh() async {
		loading(true)
		try? await Task.sleep(seconds: 2)
		await task()
	}
	func syncContacts() async {
		do {
			loading(true)
			try await PhoneContactsService.shared.syncContacts()
			await refresh()
		} catch {
			await showError(error)
		}
	}

	func syncGroups(currentUserId: String) async {
		loading(true)
		do {
			let groups: [Group] = try await FirestoreRepo.getModels(
				for: currentUserId,
				collection: .groups,
				field: .members
			)
			let store = await Store.shared.groupStore

			try await withThrowingTaskGroup(of: Void.self) { taskGroup in
				for group in groups {
					taskGroup.addTask {
						if try await store?.exists(uid: group.uid) == false {
							try await store?.insert(group)
						} else {
							try await store?.updateAndSave(uid: group.uid) { model in
								model.update(from: group)
							}
						}
						try await ContactRepo.getOrCreate(for: group.members, refatch: false)
					}
				}
				try await taskGroup.waitForAll()
			}
			await refresh()
		} catch {
			loading(false)
			await showError(error)
		}
	}
	func loading(_ isLoading: Bool) {
		guard self.isLoading != isLoading else { return }
		self.isLoading = isLoading
	}

}

public extension Contact {
	var firstCharacter: String {
		if let first = name.first {
			return String(first).uppercased()
		}
		return ""
	}
}
