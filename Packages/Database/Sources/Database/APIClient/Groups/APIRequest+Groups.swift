//  APIRequest+Groups.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Foundation

extension Request {
    struct GroupGet: APIRequest {
        typealias Response = Group?
        let method: HTTPMethod = .get
        let path: API.Path = .groups
        let endPaths: [String]
        var allowsNotFound: Bool { true }
        func responseWhenNotFound() -> Group? { nil }
        init(groupID: String) {
            endPaths = [groupID]
        }

        static func validate(identifier: String) throws -> String {
            let identifier = identifier.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !identifier.isEmpty, identifier.count <= 128 else {
                throw HTTPError.invalidRequest("The group identifier is invalid.")
            }
            return identifier
        }
    }

    struct GroupList: APIRequest {
        typealias Response = GroupListResponse
        let method: HTTPMethod = .get
        let path: API.Path = .groups
        let endPaths: [String] = []

        let pageSize: Int
        let cursor: String?
        var queryItems: [URLQueryItem] {
            var items = [URLQueryItem(name: "limit", value: String(pageSize))]
            if let cursor {
                items.append(URLQueryItem(name: "after", value: cursor))
            }
            return items
        }
    }

    struct GroupUpsert: APIRequest {
        typealias Response = Group
        let method: HTTPMethod = .put
        let path: API.Path = .groups
        let endPaths: [String]
        let body: HTTPRequestBody?

        init(group: Group) {
            endPaths = [group.uid]
            body = .encodable(GroupUpsertRequest(group))
        }

        static func validate(_ group: Group) throws {
            _ = try GroupGet.validate(identifier: group.uid)
            let name = group.name.trimmingCharacters(in: .whitespacesAndNewlines)
            var seen = Set<String>()
            let members = group.members.filter { seen.insert($0).inserted }
            guard !name.isEmpty, name.count <= 100,
                members.count >= 2, members.count <= 256,
                members.allSatisfy({ !$0.isEmpty && $0.count <= 128 })
            else {
                throw HTTPError.invalidRequest("The group contains invalid values.")
            }
            if let photoURL = group.photoURL, !photoURL.isEmpty {
                guard photoURL.count <= 2048,
                    let url = URL(string: photoURL),
                    url.scheme?.lowercased() == "https",
                    url.host != nil
                else {
                    throw HTTPError.invalidRequest("The group photo URL is invalid.")
                }
            }
        }
    }

    struct GroupDelete: APIRequest {
        typealias Response = EmptyResponse
        let method: HTTPMethod = .delete
        let path: API.Path = .groups
        let endPaths: [String]
        var acceptsEmptyResponse: Bool { true }
        func responseWhenNotFound() -> EmptyResponse { EmptyResponse() }

        init(groupID: String) {
            endPaths = [groupID]
        }

        static func validate(identifier: String) throws -> String {
            try GroupGet.validate(identifier: identifier)
        }
    }
}
