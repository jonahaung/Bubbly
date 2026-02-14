protocol PlaygroundReducer {
	func reduce(state: inout PlaygroundViewState, action: PlaygroundAction)
}

struct PlaygroundReducerImpl: PlaygroundReducer {
	func reduce(state: inout PlaygroundViewState, action: PlaygroundAction) {
		switch action {
		case let .setLoading(value):
			state = .init(isLoading: value, error: state.error)
		case let .setError(value):
			state = .init(isLoading: state.isLoading, error: value)
		case let .applySnapshot(snapshot):
			state = .init(isLoading: snapshot.isLoading, error: snapshot.error)
		}
	}
}
