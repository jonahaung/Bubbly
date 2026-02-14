protocol ContactsReducer {
	func reduce(state: inout ContactsViewState, action: ContactsAction)
}

struct ContactsReducerImpl: ContactsReducer {
	func reduce(state: inout ContactsViewState, action: ContactsAction) {
		switch action {
		case let .setLoading(value):
			state = ContactsViewState(
				isLoading: value,
				error: state.error,
				searchText: state.searchText
			)
		case let .setError(value):
			state = ContactsViewState(
				isLoading: state.isLoading,
				error: value,
				searchText: state.searchText
			)
		case let .applySnapshot(snapshot):
			state = ContactsViewState(
				isLoading: snapshot.isLoading,
				error: snapshot.error,
				searchText: snapshot.searchText
			)
		}
	}
}
