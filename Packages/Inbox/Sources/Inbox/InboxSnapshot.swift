// © 2026 Aung Ko Min

import Database

// MARK: - InboxSnapshot

struct InboxSnapshot {
    let items: [InboxItem]
}

// MARK: - InboxRepository

@MainActor
protocol InboxRepository {
    func observe(currentUser: CurrentUserModel) async throws -> InboxSnapshot
    func refresh() async throws -> InboxSnapshot
    func latestSnapshot() async -> InboxSnapshot
}
