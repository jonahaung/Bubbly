import Database
import XUI

protocol ContactListReducer {
    func reduce(state: inout ContactListViewState, action: ContactListAction)
}

struct ContactListReducerImpl: ContactListReducer {
    func reduce(state: inout ContactListViewState, action: ContactListAction) {
        switch action {
        case .setLoading(let value):
            state.isLoading = value
        case .setError(let value):
            state.error = value
        case .setSearchText(let value):
            state.searchText = value
            state.chatContactSections = buildSections(from: filteredContacts(for: state.chatContacts, searchText: value))
            state.phoneContactSections = buildSections(from: filteredContacts(for: state.phoneContacts, searchText: value))
        case .applySnapshot(let snapshot):
            state = .init(
                searchText: state.searchText,
                chatContacts: snapshot.contacts,
                phoneContacts: snapshot.phoneContacts,
                groups: snapshot.groups,
                chatContactSections: buildSections(from: filteredContacts(for: snapshot.contacts, searchText: state.searchText)),
                phoneContactSections: buildSections(from: filteredContacts(for: snapshot.phoneContacts, searchText: state.searchText)),
                isLoading: snapshot.isLoading,
                error: snapshot.error
            )
        }
    }

    private func filteredContacts(for contacts: [Contact], searchText: String) -> [Contact] {
        guard !searchText.isEmpty else {
            return contacts
        }
        return contacts.filter { $0.name.localizedStandardContains(searchText) }
    }

    private func buildSections(from contacts: [Contact]) -> [ContactListSection] {
        contacts
            .groupByKey(keyPath: \.firstCharacter)
            .map { ContactListSection(id: $0.key, title: $0.key, items: $0.value) }
            .sorted { $0.id < $1.id }
    }
}
