// © 2026 Aung Ko Min

@MainActor
struct PlaygroundRepositoryImpl: PlaygroundRepository {
    private let manager: PlaygroundManager

    init(manager: PlaygroundManager) {
        self.manager = manager
    }

    func loadInitial() -> PlaygroundSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func refresh() -> PlaygroundSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func submit() -> PlaygroundSnapshot {
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func latestSnapshot() -> PlaygroundSnapshot {
        snapshot()
    }

    private func snapshot() -> PlaygroundSnapshot {
        .init(isLoading: manager.isLoading, error: manager.error)
    }
}
