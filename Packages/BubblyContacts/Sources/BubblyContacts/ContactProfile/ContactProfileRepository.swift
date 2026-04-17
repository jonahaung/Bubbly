import Database

struct ContactProfileSnapshot {
    let contact: Contact
    let properties: ConversationProperties
    let isLoading: Bool
    let isDeletingMessages: Bool
    let error: String?
}

@MainActor
protocol ContactProfileRepository {
    func loadInitial() async throws -> ContactProfileSnapshot
    func refresh() async throws -> ContactProfileSnapshot
    func updateContact(_ contact: Contact) async throws -> ContactProfileSnapshot
    func updateProperties(_ properties: ConversationProperties) async throws -> ContactProfileSnapshot
    func deleteMessages() async throws -> ContactProfileSnapshot
    func latestSnapshot() async -> ContactProfileSnapshot
}
