import Database

struct ContactListSnapshot {
    let contacts: [Contact]
    let groups: [Group]
    let isLoading: Bool
    let error: String?
}

@MainActor
protocol ContactListRepository {
    func loadInitial() async throws -> ContactListSnapshot
    func refresh() async throws -> ContactListSnapshot
    func syncContacts() async throws -> ContactListSnapshot
    func syncGroups() async throws -> ContactListSnapshot
    func latestSnapshot() async -> ContactListSnapshot
}
