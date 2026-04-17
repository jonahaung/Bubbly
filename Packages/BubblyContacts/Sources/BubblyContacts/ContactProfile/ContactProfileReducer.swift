protocol ContactProfileReducer {
    func reduce(state: inout ContactProfileViewState, action: ContactProfileAction)
}

struct ContactProfileReducerImpl: ContactProfileReducer {
    func reduce(state: inout ContactProfileViewState, action: ContactProfileAction) {
        switch action {
        case .setLoading(let value):
            state.isLoading = value
        case .setDeletingMessages(let value):
            state.isDeletingMessages = value
        case .setError(let value):
            state.error = value
        case .applySnapshot(let snapshot):
            state = .init(
                contact: snapshot.contact,
                properties: snapshot.properties,
                isLoading: snapshot.isLoading,
                isDeletingMessages: snapshot.isDeletingMessages,
                error: snapshot.error
            )
        }
    }
}
