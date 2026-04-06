//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

public struct ContactPickerScene: View {

    @Environment(\.dismiss) private var dismiss
    @Binding var selection: [Contact]
    @State private var searchText = ""

    public init(selection: Binding<[Contact]>) {
        _selection = selection
    }

    public var body: some View {
        NavigationStack {
            List {
                if contacts.isEmpty {
                    ContentUnavailableView.search
                } else {
                    ForEach(contacts, id: \.uid) { contact in
                        let isSelected = selection.contains { $0.uid == contact.uid }
                        SelectableContactCell(
                            contact: contact,
                            isSelected: isSelected
                        ) { _ in
                            toggleSelection(for: contact)
                        }
                    }
                }
            }
            .navigationTitle("Contact Picker")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(role: .confirm) {
                        dismiss()
                    }
                    .disabled(selection.isEmpty)
                }
                ToolbarItem(placement: .cancellationAction) {
                    Button(role: .cancel) {
                        dismiss()
                    }
                    .disabled(!selection.isEmpty)
                }
            }
            .searchable(
                text: $searchText,
                placement: .automatic,
                prompt: "Search contacts"
            )
        }
        .interactiveDismissDisabled(!selection.isEmpty)
    }

    private var contacts: [Contact] {
        guard !searchText.isWhitespace else {
			return ContactsRepository.shared.contacts
        }
        return ContactsRepository.shared.contacts.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }

    private func toggleSelection(for contact: Contact) {
        if let index = selection.firstIndex(where: { $0.uid == contact.uid }) {
            selection.remove(at: index)
        } else {
            selection.append(contact)
        }
    }
}
