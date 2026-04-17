// © 2026 Aung Ko Min

// MARK: - LoadExampleUseCase

@MainActor
protocol LoadExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

// MARK: - RefreshExampleUseCase

@MainActor
protocol RefreshExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

// MARK: - SubmitExampleUseCase

@MainActor
protocol SubmitExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

// MARK: - LatestExampleSnapshotUseCase

@MainActor
protocol LatestExampleSnapshotUseCase {
    func execute() async -> ExampleSnapshot
}

// MARK: - LoadExampleUseCaseImpl

struct LoadExampleUseCaseImpl: LoadExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.loadInitial()
    }
}

// MARK: - RefreshExampleUseCaseImpl

struct RefreshExampleUseCaseImpl: RefreshExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.refresh()
    }
}

// MARK: - SubmitExampleUseCaseImpl

struct SubmitExampleUseCaseImpl: SubmitExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.submit()
    }
}

// MARK: - LatestExampleSnapshotUseCaseImpl

struct LatestExampleSnapshotUseCaseImpl: LatestExampleSnapshotUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async -> ExampleSnapshot {
        await repository.latestSnapshot()
    }
}
