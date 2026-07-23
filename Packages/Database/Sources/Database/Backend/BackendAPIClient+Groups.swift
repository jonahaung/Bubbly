import Core
import Foundation

public extension BackendAPIClient {
    func group(groupID: String) async throws -> Group? {
        let groupID = try validatedGroupIdentifier(groupID)
        guard let data = try await executor.send(
            method: "GET",
            path: ["v1", "groups", groupID],
            allowsNotFound: true
        ) else {
            return nil
        }
        return try executor.decode(Group.self, from: data)
    }

    func groups(pageSize: Int = 100) async throws -> [Group] {
        let pageSize = min(max(pageSize, 1), 100)
        var groups: [Group] = []
        var cursor: String?
        var seenCursors = Set<String>()

        repeat {
            var queryItems = [URLQueryItem(name: "limit", value: String(pageSize))]
            if let cursor {
                queryItems.append(URLQueryItem(name: "after", value: cursor))
            }
            let data = try await executor.requiredResponse(
                method: "GET",
                path: ["v1", "groups"],
                queryItems: queryItems
            )
            let page = try executor.decode(GroupListResponse.self, from: data)
            groups.append(contentsOf: page.items)
            if let nextCursor = page.nextCursor,
               !seenCursors.insert(nextCursor).inserted {
                throw BackendAPIError.invalidResponse
            }
            cursor = page.nextCursor
        } while cursor != nil

        return groups
    }

    @discardableResult
    func upsertGroup(_ group: Group) async throws -> Group {
        try validate(group)
        let data = try await executor.requiredResponse(
            method: "PUT",
            path: ["v1", "groups", group.uid],
            body: .data(try executor.encode(GroupUpsertRequest(group))),
            contentType: "application/json"
        )
        return try executor.decode(Group.self, from: data)
    }

    func deleteGroup(groupID: String) async throws {
        let groupID = try validatedGroupIdentifier(groupID)
        _ = try await executor.send(method: "DELETE", path: ["v1", "groups", groupID])
    }

    private func validate(_ group: Group) throws {
        _ = try validatedGroupIdentifier(group.uid)
        let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
        var seen = Set<String>()
        let members = group.members.filter { seen.insert($0).inserted }
        guard !name.isEmpty, name.count <= 100,
              members.count >= 2, members.count <= 256,
              members.allSatisfy({ !$0.isEmpty && $0.count <= 128 }) else {
            throw BackendAPIError.invalidRequest("The group contains invalid values.")
        }
        if let photoURL = group.photoURL, !photoURL.isEmpty {
            guard photoURL.count <= 2_048,
                  let url = URL(string: photoURL),
                  url.scheme?.lowercased() == "https",
                  url.host != nil else {
                throw BackendAPIError.invalidRequest("The group photo URL is invalid.")
            }
        }
    }

    private func validatedGroupIdentifier(_ value: String) throws -> String {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !value.isEmpty, value.count <= 128 else {
            throw BackendAPIError.invalidRequest("The group identifier is invalid.")
        }
        return value
    }
}
