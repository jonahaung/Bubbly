// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI
import Core

public struct ContactPickerScene: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var selection: [Contact]
    @State private var searchText = ""

    public init(selection: Binding<[Contact]>) {
        _selection = selection
    }

    public var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack {
                    if contacts.isEmpty {
                        ContentUnavailableView.search
                    }
                    ScrollSection(data: contacts) { contact in
                        let isSelected = selection.contains { $0.uid == contact.uid }
                        SelectableContactCell(
                            contact: contact,
                            isSelected: isSelected,
                        ) { _ in
                            toggleSelection(for: contact)
                        }
                    }
                }
                .padding(Padding.md)
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
                prompt: "Search contacts",
            )
            .onTask {
                await fetchContacts()
            }
        }
        .interactiveDismissDisabled(!selection.isEmpty)
    }

    private var contacts: [Contact] {
        guard !searchText.isWhitespace else {
            return allContacts
        }

        return allContacts.filter {
            $0.name.lowercased().contains(searchText.lowercased())
        }
    }
    
    @State private var allContacts = [Contact]()

    private func toggleSelection(for contact: Contact) {
        if let index = selection.firstIndex(where: { $0.uid == contact.uid }) {
            selection.remove(at: index)
        } else {
            selection.append(contact)
        }
    }
    
    private func fetchContacts() async {
        do {
            allContacts = try await Store.shared.contactStore?.fetchAll() ?? []
        } catch {
            log(error)
        }
    }
}
