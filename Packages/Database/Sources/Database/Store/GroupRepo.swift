import Foundation

public enum GroupRepo {
    public enum GroupError: Error, Sendable {
        case notFound
    }

    @discardableResult
    public static func getOrCreate(groupID: String, refetch: Bool) async throws -> Group {
        let store = await Store.shared.groupStore
        if !refetch, let local = try await store?.fetch(uid: groupID) {
            return local
        }
        guard let remote = try await BackendAPIClient.shared.group(groupID: groupID) else {
            throw GroupError.notFound
        }
        try await store?.insert(remote)
        return remote
    }

    @discardableResult
    public static func save(_ group: Group) async throws -> Group {
        let saved = try await BackendAPIClient.shared.upsertGroup(group)
        try await Store.shared.groupStore?.insert(saved)
        return saved
    }

    public static func sync() async throws -> [Group] {
        let remoteGroups = try await BackendAPIClient.shared.groups()
        let store = await Store.shared.groupStore
        let localGroups = try await store?.fetchAll() ?? []
        let remoteIDs = Set(remoteGroups.map(\.uid))

        for group in remoteGroups {
            try await store?.insert(group)
        }
        for group in localGroups where !remoteIDs.contains(group.uid) {
            try await store?.delete(uid: group.uid)
        }
        return remoteGroups
    }

    public static func delete(groupID: String) async throws {
        try await BackendAPIClient.shared.deleteGroup(groupID: groupID)
        try await Store.shared.groupStore?.delete(uid: groupID)
    }
}
