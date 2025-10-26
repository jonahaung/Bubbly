//
//  ContactsViewModel.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Foundation
import Database
import Services
import XUI
import FirebaseFirestore

@MainActor
@Observable
final class ContactsViewModel: ErrorPresenter {

	var loading: Bool = false
	var groups = [(String, [Contact])]()

	init() {}

	@concurrent
	func syncContacts(store: ContactStore) async {
		await setLoading(true)
		do {
			try await store.syncContacts()
			let contacts = await store.contacts
			await createSections(from: contacts)
			await setLoading(false)
		} catch {
			await showError(error)
			await setLoading(false)
		}
	}

	@MainActor func createSections(from contacts: [Contact]) {
		let group = contacts.groupByKey(keyPath: \.firstCharacter)
		let items = group.map { ($0.key, $0.value)}
		groups = items.sorted(by: { lhs, rhs in
			lhs.0 < rhs.0
		})
	}

	@MainActor private func setLoading(_ isLoading: Bool) {
		self.loading = isLoading
	}
	@concurrent func fetch() async {
		do {
			let contacts = try await Store.shared.contactStore.fetchAll()
			await createSections(from: contacts)
		} catch {
			Log(error)
		}
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
