import Database

@MainActor
protocol ObserveInboxUseCase {
	func execute(currentUser: CurrentUserModel) async throws -> InboxSnapshot
}

@MainActor
protocol RefreshInboxUseCase {
	func execute() async throws -> InboxSnapshot
}

@MainActor
protocol LatestInboxSnapshotUseCase {
	func execute() async -> InboxSnapshot
}

struct ObserveInboxUseCaseImpl: ObserveInboxUseCase {
	private let repository: InboxRepository

	init(repository: InboxRepository) {
		self.repository = repository
	}

	func execute(currentUser: CurrentUserModel) async throws -> InboxSnapshot {
		try await repository.observe(currentUser: currentUser)
	}
}

struct RefreshInboxUseCaseImpl: RefreshInboxUseCase {
	private let repository: InboxRepository

	init(repository: InboxRepository) {
		self.repository = repository
	}

	func execute() async throws -> InboxSnapshot {
		try await repository.refresh()
	}
}

struct LatestInboxSnapshotUseCaseImpl: LatestInboxSnapshotUseCase {
	private let repository: InboxRepository

	init(repository: InboxRepository) {
		self.repository = repository
	}

	func execute() async -> InboxSnapshot {
		await repository.latestSnapshot()
	}
}
