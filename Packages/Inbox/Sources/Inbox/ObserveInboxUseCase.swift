// © 2026 Aung Ko Min

import Database

// MARK: - ObserveInboxUseCase

@MainActor
protocol ObserveInboxUseCase {
    func execute(currentUser: CurrentUserModel) async throws -> InboxSnapshot
}

// MARK: - RefreshInboxUseCase

@MainActor
protocol RefreshInboxUseCase {
    func execute() async throws -> InboxSnapshot
}

// MARK: - LatestInboxSnapshotUseCase

@MainActor
protocol LatestInboxSnapshotUseCase {
    func execute() async -> InboxSnapshot
}

// MARK: - ObserveInboxUseCaseImpl

struct ObserveInboxUseCaseImpl: ObserveInboxUseCase {
    private let repository: InboxRepository

    init(repository: InboxRepository) {
        self.repository = repository
    }

    func execute(currentUser: CurrentUserModel) async throws -> InboxSnapshot {
        try await repository.observe(currentUser: currentUser)
    }
}

// MARK: - RefreshInboxUseCaseImpl

struct RefreshInboxUseCaseImpl: RefreshInboxUseCase {
    private let repository: InboxRepository

    init(repository: InboxRepository) {
        self.repository = repository
    }

    func execute() async throws -> InboxSnapshot {
        try await repository.refresh()
    }
}

// MARK: - LatestInboxSnapshotUseCaseImpl

struct LatestInboxSnapshotUseCaseImpl: LatestInboxSnapshotUseCase {
    private let repository: InboxRepository

    init(repository: InboxRepository) {
        self.repository = repository
    }

    func execute() async -> InboxSnapshot {
        await repository.latestSnapshot()
    }
}
