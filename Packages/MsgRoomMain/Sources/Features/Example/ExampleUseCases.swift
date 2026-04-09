//
//  Created by Aung Ko Min on 9/4/26.
//

@MainActor
protocol LoadExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

@MainActor
protocol RefreshExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

@MainActor
protocol SubmitExampleUseCase {
    func execute() async throws -> ExampleSnapshot
}

@MainActor
protocol LatestExampleSnapshotUseCase {
    func execute() async -> ExampleSnapshot
}

struct LoadExampleUseCaseImpl: LoadExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.loadInitial()
    }
}

struct RefreshExampleUseCaseImpl: RefreshExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.refresh()
    }
}

struct SubmitExampleUseCaseImpl: SubmitExampleUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async throws -> ExampleSnapshot {
        try await repository.submit()
    }
}

struct LatestExampleSnapshotUseCaseImpl: LatestExampleSnapshotUseCase {
    private let repository: ExampleRepository

    init(repository: ExampleRepository) {
        self.repository = repository
    }

    func execute() async -> ExampleSnapshot {
        await repository.latestSnapshot()
    }
}
