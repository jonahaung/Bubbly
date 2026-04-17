import Database

@MainActor
protocol LoadContactProfileUseCase {
    func execute() async throws -> ContactProfileSnapshot
}

@MainActor
protocol RefreshContactProfileUseCase {
    func execute() async throws -> ContactProfileSnapshot
}

@MainActor
protocol UpdateContactProfileContactUseCase {
    func execute(contact: Contact) async throws -> ContactProfileSnapshot
}

@MainActor
protocol UpdateContactProfilePropertiesUseCase {
    func execute(properties: ConversationProperties) async throws -> ContactProfileSnapshot
}

@MainActor
protocol DeleteContactProfileMessagesUseCase {
    func execute() async throws -> ContactProfileSnapshot
}

@MainActor
protocol LatestContactProfileSnapshotUseCase {
    func execute() async -> ContactProfileSnapshot
}

struct LoadContactProfileUseCaseImpl: LoadContactProfileUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactProfileSnapshot {
        try await repository.loadInitial()
    }
}

struct RefreshContactProfileUseCaseImpl: RefreshContactProfileUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactProfileSnapshot {
        try await repository.refresh()
    }
}

struct UpdateContactProfileContactUseCaseImpl: UpdateContactProfileContactUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute(contact: Contact) async throws -> ContactProfileSnapshot {
        try await repository.updateContact(contact)
    }
}

struct UpdateContactProfilePropertiesUseCaseImpl: UpdateContactProfilePropertiesUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute(properties: ConversationProperties) async throws -> ContactProfileSnapshot {
        try await repository.updateProperties(properties)
    }
}

struct DeleteContactProfileMessagesUseCaseImpl: DeleteContactProfileMessagesUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute() async throws -> ContactProfileSnapshot {
        try await repository.deleteMessages()
    }
}

struct LatestContactProfileSnapshotUseCaseImpl: LatestContactProfileSnapshotUseCase {
    private let repository: ContactProfileRepository

    init(repository: ContactProfileRepository) {
        self.repository = repository
    }

    func execute() async -> ContactProfileSnapshot {
        await repository.latestSnapshot()
    }
}
