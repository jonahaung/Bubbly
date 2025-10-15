//
//  ContactPickerScene.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 24/8/25.
//

import SwiftUI
import Database
import Services
import XUI

public struct ContactPickerScene: View {

	@Environment(ContactStore.self) private var contactStore
	@Environment(\.dismiss) private var dismiss
	@Binding var selection: [ContactSnapshot]
	@State private var searchText = ""

	public init(selection: Binding<[ContactSnapshot]>) {
		self._selection = selection
	}

	public var body: some View {
		NavigationStack {
			List {
				Section {
					if contacts.isEmpty {
						ContentUnavailableView.search
					} else {
						ForEach(contacts) { contact in
							let isSelected = selection.contains { $0.uid == contact.uid }
							SelectableContactCell(
								contact: contact,
								isSelected: isSelected
							) { _ in
								toggleSelection(for: contact)
							}
						}
					}
				} header: {
					Text("Select contacts")
				}
			}
			.navigationTitle("Contact Picker")
			.navigationBarTitleDisplayMode(.inline)
			.toolbar {
				ToolbarItem(placement: .topBarTrailing) {
					Button("Done") {
						dismiss()
					}
				}
			}
			.searchable(
				text: $searchText,
				placement: .navigationBarDrawer(displayMode: .automatic),
				prompt: "Search contacts"
			)
		}
		.interactiveDismissDisabled()
	}

	private var contacts: [ContactSnapshot] {
		guard !searchText.isWhitespace else {
			return contactStore.availableContacts
		}
		return contactStore.availableContacts.filter {
			$0.name.lowercased().contains(searchText.lowercased())
		}
	}

	private func toggleSelection(for contact: ContactSnapshot) {
		if let index = selection.firstIndex(where: { $0.uid == contact.uid }) {
			selection.remove(at: index)
		} else {
			selection.append(contact)
		}
	}
}
