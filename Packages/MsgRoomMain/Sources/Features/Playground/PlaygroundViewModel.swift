//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Observation

@MainActor
@Observable
final class PlaygroundViewModel {
    private(set) var state: PlaygroundViewState

    private let reducer: PlaygroundReducer
    private let taskRegistry = PlaygroundTaskRegistry()
    private let loadUseCase: LoadPlaygroundUseCase
    private let refreshUseCase: RefreshPlaygroundUseCase
    private let submitUseCase: SubmitPlaygroundUseCase

    init(reducer: PlaygroundReducer = PlaygroundReducerImpl()) {
        self.reducer = reducer
        let manager = PlaygroundManager()
        let repository = PlaygroundRepositoryImpl(manager: manager)
        loadUseCase = LoadPlaygroundUseCaseImpl(repository: repository)
        refreshUseCase = RefreshPlaygroundUseCaseImpl(repository: repository)
        submitUseCase = SubmitPlaygroundUseCaseImpl(repository: repository)
        state = .init(isLoading: false, error: nil)
    }

    func send(_ intent: PlaygroundIntent) async {
        switch intent {
        case .appear:
            await taskRegistry.run(key: .appear) { [weak self] in
                guard let self else { return }
                await load()
            }
        case .refresh:
            await taskRegistry.run(key: .refresh) { [weak self] in
                guard let self else { return }
                await refresh()
            }
        case .submit:
            await taskRegistry.run(key: .submit) { [weak self] in
                guard let self else { return }
                await submit()
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
            let snapshot = try await submitUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func dispatch(_ action: PlaygroundAction) {
        reducer.reduce(state: &state, action: action)
    }
}
