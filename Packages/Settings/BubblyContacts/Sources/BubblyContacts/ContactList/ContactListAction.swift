enum ContactListAction {
    case setLoading(Bool)
    case setError(String?)
    case setSearchText(String)
    case applySnapshot(ContactListSnapshot)
}
