import Database

struct InboxSnapshot {
	let items: [InboxItem]
}

@MainActor
protocol InboxRepository {
	func observe(currentUser: CurrentUserModel) async throws -> InboxSnapshot
	func refresh() async throws -> InboxSnapshot
	func latestSnapshot() async -> InboxSnapshot
}
