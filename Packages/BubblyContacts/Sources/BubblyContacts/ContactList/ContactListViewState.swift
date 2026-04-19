import Database

struct ContactListViewState {
    var searchText: String
    var chatContacts: [Contact]
    var phoneContacts: [Contact]
    var groups: [Group]
    var chatContactSections: [ContactListSection]
    var phoneContactSections: [ContactListSection]
    var isLoading: Bool
    var error: String?
}

struct ContactListSection: Identifiable, Equatable {
    let id: String
    var title: String
    var items: [Contact]
}
