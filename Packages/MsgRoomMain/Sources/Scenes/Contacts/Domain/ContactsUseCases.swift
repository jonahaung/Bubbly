@MainActor
protocol LoadContactsUseCase {
	func execute() async throws -> ContactsSnapshot
}

@MainActor
protocol RefreshContactsUseCase {
	func execute() async throws -> ContactsSnapshot
}

@MainActor
protocol SyncContactsUseCase {
	func execute() async throws -> ContactsSnapshot
}

@MainActor
protocol SyncGroupsUseCase {
	func execute() async throws -> ContactsSnapshot
}

@MainActor
protocol SetContactsSearchTextUseCase {
	func execute(_ value: String) async -> ContactsSnapshot
}

@MainActor
protocol LatestContactsSnapshotUseCase {
	func execute() async -> ContactsSnapshot
}

struct LoadContactsUseCaseImpl: LoadContactsUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute() async throws -> ContactsSnapshot {
		try await repository.loadInitial()
	}
}

struct RefreshContactsUseCaseImpl: RefreshContactsUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute() async throws -> ContactsSnapshot {
		try await repository.refresh()
	}
}

struct SyncContactsUseCaseImpl: SyncContactsUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute() async throws -> ContactsSnapshot {
		try await repository.syncContacts()
	}
}

struct SyncGroupsUseCaseImpl: SyncGroupsUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute() async throws -> ContactsSnapshot {
		try await repository.syncGroups()
	}
}

struct SetContactsSearchTextUseCaseImpl: SetContactsSearchTextUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute(_ value: String) async -> ContactsSnapshot {
		await repository.updateSearchText(value)
	}
}

struct LatestContactsSnapshotUseCaseImpl: LatestContactsSnapshotUseCase {
	private let repository: ContactsSceneRepository

	init(repository: ContactsSceneRepository) {
		self.repository = repository
	}

	func execute() async -> ContactsSnapshot {
		await repository.latestSnapshot()
	}
}
