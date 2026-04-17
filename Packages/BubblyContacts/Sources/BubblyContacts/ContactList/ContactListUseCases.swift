import Database

@MainActor
protocol LoadContactListUseCase {
    func execute() async throws -> ContactListSnapshot
}

@MainActor
protocol RefreshContactListUseCase {
    func execute() async throws -> ContactListSnapshot
}

@MainActor
protocol SyncContactListContactsUseCase {
    func execute() async throws -> ContactListSnapshot
}

@MainActor
protocol SyncContactListGroupsUseCase {
    func execute() async throws -> ContactListSnapshot
}

@MainActor
protocol LatestContactListSnapshotUseCase {
    func execute() async -> ContactListSnapshot
}

struct LoadContactListUseCaseImpl: LoadContactListUseCase {
    private let repository: ContactListRepository

    init(repository: ContactListRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactListSnapshot {
        try await repository.loadInitial()
    }
}

struct RefreshContactListUseCaseImpl: RefreshContactListUseCase {
    private let repository: ContactListRepository

    init(repository: ContactListRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactListSnapshot {
        try await repository.refresh()
    }
}

struct SyncContactListContactsUseCaseImpl: SyncContactListContactsUseCase {
    private let repository: ContactListRepository

    init(repository: ContactListRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactListSnapshot {
        try await repository.syncContacts()
    }
}

struct SyncContactListGroupsUseCaseImpl: SyncContactListGroupsUseCase {
    private let repository: ContactListRepository

    init(repository: ContactListRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactListSnapshot {
        try await repository.syncGroups()
    }
}

struct LatestContactListSnapshotUseCaseImpl: LatestContactListSnapshotUseCase {
    private let repository: ContactListRepository

    init(repository: ContactListRepository) {
        self.repository = repository
    }

    func execute() async -> ContactListSnapshot {
        await repository.latestSnapshot()
    }
}
