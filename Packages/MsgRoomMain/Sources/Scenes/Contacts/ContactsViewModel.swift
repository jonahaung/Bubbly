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
final class ContactsViewModel {

	var loading: Bool = false
	var groups = [(String, [ContactSnapshot])]()

	init() {}

	func syncContacts(store: ContactStore) async throws {
		setLoading(true)
		try await store.syncContacts()
		let contacts = store.contacts
		createSections(from: contacts)
		setLoading(false)
	}

	@MainActor func createSections(from contacts: [ContactSnapshot]) {
		let group = contacts.groupByKey(keyPath: \.firstCharacter)
		let items = group.map { ($0.key, $0.value)}
		groups = items.sorted(by: { lhs, rhs in
			lhs.0 < rhs.0
		})
	}

	@MainActor private func setLoading(_ isLoading: Bool) {
		self.loading = isLoading
	}
}

public extension ContactSnapshot {
	var firstCharacter: String {
		if let first = name.first {
			return String(first).uppercased()
		}
		return ""
	}
}
