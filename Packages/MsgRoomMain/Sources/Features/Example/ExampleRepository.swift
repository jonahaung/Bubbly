// © 2026 Aung Ko Min

// MARK: - ExampleSnapshot

struct ExampleSnapshot {
    let isLoading: Bool
    let error: String?
    let items: [String]
}

// MARK: - ExampleRepository

@MainActor
protocol ExampleRepository {
    func loadInitial() async throws -> ExampleSnapshot
    func refresh() async throws -> ExampleSnapshot
    func submit() async throws -> ExampleSnapshot
    func latestSnapshot() async -> ExampleSnapshot
}
