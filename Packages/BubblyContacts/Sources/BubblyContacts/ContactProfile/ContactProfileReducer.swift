//  ContactProfileReducer.swift
//
//  Copyright © 2026 Aung Ko Min.
//

protocol ContactProfileReducer {
    func reduce(state: inout ContactProfileViewState, action: ContactProfileAction)
}

struct ContactProfileReducerImpl: ContactProfileReducer {
    func reduce(state: inout ContactProfileViewState, action: ContactProfileAction) {
        switch action {
        case let .setLoading(value):
            state.isLoading = value
        case let .setDeletingMessages(value):
            state.isDeletingMessages = value
        case let .setError(value):
            state.error = value
        case let .applySnapshot(snapshot):
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
