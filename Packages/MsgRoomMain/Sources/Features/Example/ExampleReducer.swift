// © 2026 Aung Ko Min

// MARK: - ExampleReducer

protocol ExampleReducer {
    func reduce(state: inout ExampleViewState, action: ExampleAction)
}

// MARK: - ExampleReducerImpl

struct ExampleReducerImpl: ExampleReducer {
    func reduce(state: inout ExampleViewState, action: ExampleAction) {
        switch action {
        case let .setLoading(value):
            state = .init(isLoading: value, error: state.error, items: nil)
        case let .setError(value):
            state = .init(isLoading: state.isLoading, error: value, items: nil)
        case let .applySnapshot(snapshot):
            state = .init(
                isLoading: snapshot.isLoading,
                error: snapshot.error,
                items: snapshot.items,
            )
        }
    }
}
