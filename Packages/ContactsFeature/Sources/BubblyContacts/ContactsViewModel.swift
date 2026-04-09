//
//  ContactsViewModel.swift
//  Contacts
//
//  Created by Aung Ko Min on 6/4/26.
//


import Database
import Observation
import Services
import XUI

@MainActor
@Observable
final class ContactsViewModel: ErrorPresenter {

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
			contacts = try await PhoneContactsService.shared.syncContacts()
			loading(false)
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
			try await AsyncOrderedStream.mapOrdered(inputs: groups) { group in
				try await store?.insert(group)
			}
			let ids = groups.flatMap{ $0.members }.removeDuplicates()
			try await AsyncOrderedStream.mapOrdered(inputs: ids) { uid in
				try await ContactRepo.getOrCreate(uid: uid, refetch: false)
			}
			self.groups = groups
			loading(false)
			await task()
		} catch {
			loading(false)
			await showError(error)
		}
	}
	func loading(_ isLoading: Bool) {
		Loading.show(isLoading)
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
