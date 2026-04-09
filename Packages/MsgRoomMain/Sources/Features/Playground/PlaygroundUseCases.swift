//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

@MainActor
protocol LoadPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

@MainActor
protocol RefreshPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

@MainActor
protocol SubmitPlaygroundUseCase {
    func execute() async throws -> PlaygroundSnapshot
}

@MainActor
protocol LatestPlaygroundSnapshotUseCase {
    func execute() async -> PlaygroundSnapshot
}

struct LoadPlaygroundUseCaseImpl: LoadPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.loadInitial()
    }
}

struct RefreshPlaygroundUseCaseImpl: RefreshPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.refresh()
    }
}

struct SubmitPlaygroundUseCaseImpl: SubmitPlaygroundUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async throws -> PlaygroundSnapshot {
        try await repository.submit()
    }
}

struct LatestPlaygroundSnapshotUseCaseImpl: LatestPlaygroundSnapshotUseCase {
    private let repository: PlaygroundRepository

    init(repository: PlaygroundRepository) {
        self.repository = repository
    }

    func execute() async -> PlaygroundSnapshot {
        await repository.latestSnapshot()
    }
}
