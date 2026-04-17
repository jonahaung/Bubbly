// © 2026 Aung Ko Min

// MARK: - LoadPlaygroundUseCase

@MainActor
protocol LoadPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

// MARK: - RefreshPlaygroundUseCase

@MainActor
protocol RefreshPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

// MARK: - SubmitPlaygroundUseCase

@MainActor
protocol SubmitPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

// MARK: - LatestPlaygroundSnapshotUseCase

@MainActor
protocol LatestPlaygroundSnapshotUseCase {
    func execute() async -> PlaygroundSnapshot
}

// MARK: - LoadPlaygroundUseCaseImpl

struct LoadPlaygroundUseCaseImpl: LoadPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.loadInitial()
    }
}

// MARK: - RefreshPlaygroundUseCaseImpl

struct RefreshPlaygroundUseCaseImpl: RefreshPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.refresh()
    }
}

// MARK: - SubmitPlaygroundUseCaseImpl

struct SubmitPlaygroundUseCaseImpl: SubmitPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.submit()
    }
}

// MARK: - LatestPlaygroundSnapshotUseCaseImpl

struct LatestPlaygroundSnapshotUseCaseImpl: LatestPlaygroundSnapshotUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async -> PlaygroundSnapshot {
        await repository.latestSnapshot()
    }
}
