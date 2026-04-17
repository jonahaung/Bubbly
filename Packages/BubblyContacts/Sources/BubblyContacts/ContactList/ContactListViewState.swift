import Database

struct ContactListViewState {
    var searchText: String
    var contacts: [Contact]
    var groups: [Group]
    var sections: [ContactListSection]
    var isLoading: Bool
    var error: String?
}

struct ContactListSection: Identifiable, Equatable {
    let id: String
    var title: String
    var items: [Contact]
}
