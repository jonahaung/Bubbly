//
//  Created by Aung Ko Min on 9/4/26.
//

import Observation

@MainActor
@Observable
final class ExampleViewModel {
    private(set) var state: ExampleViewState

    private let reducer: ExampleReducer
    private let taskRegistry = ExampleTaskRegistry()
    private let loadUseCase: LoadExampleUseCase
    private let refreshUseCase: RefreshExampleUseCase
    private let submitUseCase: SubmitExampleUseCase

    init(reducer: ExampleReducer = ExampleReducerImpl()) {
        self.reducer = reducer
        let manager = ExampleManager()
        let repository = ExampleRepositoryImpl(manager: manager)
        self.loadUseCase = LoadExampleUseCaseImpl(repository: repository)
        self.refreshUseCase = RefreshExampleUseCaseImpl(repository: repository)
        self.submitUseCase = SubmitExampleUseCaseImpl(repository: repository)
		self.state = .init(isLoading: false, error: nil, items: nil)
    }

    func send(_ intent: ExampleIntent) async {
        switch intent {
        case .appear:
            await taskRegistry.run(key: .appear) { [weak self] in
                guard let self else { return }
                await self.load()
            }
        case .refresh:
            await taskRegistry.run(key: .refresh) { [weak self] in
                guard let self else { return }
                await self.refresh()
            }
        case .submit:
            await taskRegistry.run(key: .submit) { [weak self] in
                guard let self else { return }
                await self.submit()
            }
        }
    }

    private func load() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await loadUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func refresh() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await refreshUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func submit() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await loadUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func dispatch(_ action: ExampleAction) {
        reducer.reduce(state: &state, action: action)
    }
}
