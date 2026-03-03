//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

struct ContactsSnapshot {
    let isLoading: Bool
    let error: String?
    let searchText: String
}

@MainActor
protocol ContactsSceneRepository {
    func loadInitial() async throws -> ContactsSnapshot
    func refresh() async throws -> ContactsSnapshot
    func syncContacts() async throws -> ContactsSnapshot
    func syncGroups() async throws -> ContactsSnapshot
    func updateSearchText(_ value: String) async -> ContactsSnapshot
    func latestSnapshot() async -> ContactsSnapshot
}
