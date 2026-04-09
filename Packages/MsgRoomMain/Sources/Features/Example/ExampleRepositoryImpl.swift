//
//  Created by Aung Ko Min on 9/4/26.
//

@MainActor
struct ExampleRepositoryImpl: ExampleRepository {
    private let manager: ExampleManager

    init(manager: ExampleManager) {
        self.manager = manager
    }

    func loadInitial() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func refresh() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func submit() async throws -> ExampleSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func latestSnapshot() async -> ExampleSnapshot {
        snapshot()
    }

    private func snapshot() -> ExampleSnapshot {
        .init(isLoading: manager.isLoading, error: manager.error)
    }
}
