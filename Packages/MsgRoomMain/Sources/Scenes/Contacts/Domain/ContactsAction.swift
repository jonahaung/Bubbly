enum ContactsAction {
	case setLoading(Bool)
	case setError(String?)
	case applySnapshot(ContactsSnapshot)
}
