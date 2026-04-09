//
//  Created by Aung Ko Min on 9/4/26.
//

protocol ExampleReducer {
    func reduce(state: inout ExampleViewState, action: ExampleAction)
}

struct ExampleReducerImpl: ExampleReducer {
    func reduce(state: inout ExampleViewState, action: ExampleAction) {
        switch action {
        case .setLoading(let value):
			state = .init(isLoading: value, error: state.error, items: nil)
        case .setError(let value):
			state = .init(isLoading: state.isLoading, error: value, items: nil)
        case .applySnapshot(let snapshot):
			state = .init(
				isLoading: snapshot.isLoading,
				error: snapshot.error,
				items: snapshot.items
			)
        }
    }
}
