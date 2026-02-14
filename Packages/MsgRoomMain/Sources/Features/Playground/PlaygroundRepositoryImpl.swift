@MainActor
struct PlaygroundRepositoryImpl: PlaygroundRepository {
	private let manager: PlaygroundManager

	init(manager: PlaygroundManager) {
		self.manager = manager
	}

	func loadInitial() async throws -> PlaygroundSnapshot {
		manager.setLoading(false)
		manager.setError(nil)
		return snapshot()
	}

	func refresh() async throws -> PlaygroundSnapshot {
		manager.setLoading(false)
		manager.setError(nil)
		return snapshot()
	}

	func submit() async throws -> PlaygroundSnapshot {
		manager.setLoading(false)
		manager.setError(nil)
		return snapshot()
	}

	func latestSnapshot() async -> PlaygroundSnapshot {
		snapshot()
	}

	private func snapshot() -> PlaygroundSnapshot {
		.init(isLoading: manager.isLoading, error: manager.error)
	}
}
