enum ContactProfileAction {
    case setLoading(Bool)
    case setDeletingMessages(Bool)
    case setError(String?)
    case applySnapshot(ContactProfileSnapshot)
}
