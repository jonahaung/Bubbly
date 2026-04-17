// © 2026 Aung Ko Min

// MARK: - PlaygroundSnapshot

struct PlaygroundSnapshot {
    let isLoading: Bool
    let error: String?
}

// MARK: - PlaygroundRepository

@MainActor
protocol PlaygroundRepository {
    func loadInitial() async throws -> PlaygroundSnapshot
    func refresh() async throws -> PlaygroundSnapshot
    func submit() async throws -> PlaygroundSnapshot
    func latestSnapshot() async -> PlaygroundSnapshot
}
