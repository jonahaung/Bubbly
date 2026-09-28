//  GroupHttpClient.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import Shared
import Foundation

public actor GroupHttpClient {

    public static let shared: GroupHttpClient = .init()

    let client: HTTPClient

    public init() {
        client = .shared
    }

    init(client: HTTPClient) {
        self.client = client
    }

    public func group(groupID: String) async throws -> Group? {
        let groupID = try Request.GroupGet.validate(identifier: groupID)
        return try await client.executor.send(Request.GroupGet(groupID: groupID))
    }

    public func groups(pageSize: Int = 100) async throws -> [Group] {
        let pageSize = min(max(pageSize, 1), 100)
        var groups = [Group]()
        var cursor: String?
        var seenCursors = Set<String>()

        repeat {
            let page = try await client.executor.send(
                Request.GroupList(pageSize: pageSize, cursor: cursor)
            )
            groups.append(contentsOf: page.items)
            if let nextCursor = page.nextCursor,
                !seenCursors.insert(nextCursor).inserted
            {
                throw HTTPError.invalidResponse
            }
            cursor = page.nextCursor
        } while cursor != nil

        return groups
    }

    @discardableResult
    public func upsertGroup(_ group: Group) async throws -> Group {
        try Request.GroupUpsert.validate(group)
        return try await client.executor.send(Request.GroupUpsert(group: group))
    }

    public func deleteGroup(groupID: String) async throws {
        let groupID = try Request.GroupDelete.validate(identifier: groupID)
        _ = try await client.executor.send(Request.GroupDelete(groupID: groupID))
    }
}
