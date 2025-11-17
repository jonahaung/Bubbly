//
//  FirestoreRESTClient.swift
//  Database
//
//  Created by Aung Ko Min on 28/10/25.
//

import Core
import FirebaseAuth
import FirebaseFirestore
import Foundation
import XUI

@NetworkActor
public final class FirestoreRESTClient {
    public enum FirestoreError: Error {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case serverError(String)
        case notAuthenticated
        case decodingError(Error)
    }

    private let projectId: String
    private let database: String
    private let baseURL: String
    private let decoder: JSONDecoder
    private let netWorkManager = NetworkManager()

    public init(projectId: String = AppInformation.firebaseProjectID, database: String = "(default)") {
        self.projectId = projectId
        self.database = database
        baseURL = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/\(database)/documents"
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
    }

    private func performRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil,
        retry: Bool = false,
        token: String? = nil
    ) async throws -> [String: Any] {
        var request = URLRequest(url: url)
        request.httpMethod = method
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let (data, response) = try await netWorkManager.request(request)
        guard let http = response as? HTTPURLResponse else { throw FirestoreError.invalidResponse }

        switch http.statusCode {
        case 200 ..< 300:
            if data.isEmpty { return [:] }
            let json = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            return json ?? [:]
        case 401 where retry:
            let token = try await getValidAuthToken(forceRefresh: true)
            return try await performRequest(url: url, method: method, body: body, retry: false, token: token)
        default:
            throw FirestoreError.serverError(String(data: data, encoding: .utf8) ?? "Unknown server error")
        }
    }

    public func getDocument<T: Codable>(at path: String, as _: T.Type) async throws -> T {
        let url = URL(string: "\(baseURL)/\(path)")!
        let json = try await performRequest(url: url, method: "GET")
        guard let fields = json["fields"] as? [String: Any] else {
            throw FirestoreError.invalidResponse
        }
        let decoded = try decodeFirestoreDocument(fields: fields, as: T.self)
        return decoded
    }

    public func createDocument(in collectionPath: String, documentID: String, data: some Codable) async throws {
        try await Firestore
            .firestore()
            .collection(
                collectionPath
            )
            .document(
                documentID
            )
            .setData(
                data.dictionary,
                merge: false
            )
    }

    public func update(
        value: [String: Any],
        collectionPath: String,
        to documentID: String
    ) async throws {
        try await Firestore.firestore().collection(collectionPath).document(documentID).setData(value, merge: true)
        debugPrint("\(documentID) updated to \(value)")
    }

    private func runQuery<T: Codable>(
        collection: String,
        filters: [[String: Any]] = [],
        orderBy: [String]? = nil,
        limit: Int? = nil,
        as type: T.Type,
        retry: Bool = true,
        token: String? = nil
    ) async throws -> [T] {
        let url = URL(string: "\(baseURL):runQuery")!

        var structuredQuery: [String: Any] = [
            "from": [["collectionId": collection]],
        ]

        if !filters.isEmpty {
            structuredQuery["where"] = [
                "compositeFilter": [
                    "op": "AND",
                    "filters": filters,
                ],
            ]
        }

        if let orderBy {
            structuredQuery["orderBy"] = orderBy.map { ["field": ["fieldPath": $0], "direction": "ASCENDING"] }
        }

        if let limit {
            structuredQuery["limit"] = limit
        }

        let body = ["structuredQuery": structuredQuery]
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONSerialization.data(withJSONObject: body)

        let (data, response) = try await netWorkManager.request(request)
        guard let http = response as? HTTPURLResponse else { throw FirestoreError.invalidResponse }

        switch http.statusCode {
        case 200 ..< 300:
            guard let jsonArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]] else {
                return []
            }

            return try jsonArray.compactMap { item -> T? in
                guard let document = item["document"] as? [String: Any],
                      let fields = document["fields"] as? [String: Any]
                else {
                    return nil
                }
                return try decodeFirestoreDocument(fields: fields, as: T.self)
            }
        case 401 where retry:
            let token = try await getValidAuthToken(forceRefresh: true)
            return try await runQuery(
                collection: collection,
                filters: filters,
                orderBy: orderBy,
                limit: limit,
                as: type,
                token: token
            )
        default:
            throw FirestoreError.serverError(String(data: data, encoding: .utf8) ?? "Unknown server error")
        }
    }

    private func getValidAuthToken(forceRefresh: Bool = false) async throws -> String {
        let cached = GroupStorage.shared.string(for: .auth(.authToken))
        if !forceRefresh, let cached {
            return cached
        }
        guard let user = Auth.auth().currentUser else {
            throw FirestoreError.notAuthenticated
        }
        let token = try await user.getIDTokenResult(forcingRefresh: forceRefresh).token
        GroupStorage.shared.save(token, for: .auth(.authToken))
        return token
    }

    private func decodeFirestoreDocument<T: Codable>(
        fields: [String: Any],
        as _: T.Type
    ) throws -> T {
        func unwrap(_ value: Any) -> Any? {
            guard let field = value as? [String: Any] else { return nil }

            if let stringValue = field["stringValue"] as? String {
                return stringValue
            } else if let intString = field["integerValue"] as? String, let intVal = Int(intString) {
                return intVal
            } else if let doubleValue = field["doubleValue"] as? Double {
                return doubleValue
            } else if let boolValue = field["booleanValue"] as? Bool {
                return boolValue
            } else if let timestamp = field["timestampValue"] as? String {
                return timestamp
            } else if field["nullValue"] != nil {
                return NSNull()
            } else if let array = field["arrayValue"] as? [String: Any],
                      let values = array["values"] as? [Any]
            {
                return values.compactMap(unwrap)
            } else if let map = field["mapValue"] as? [String: Any],
                      let nestedFields = map["fields"] as? [String: Any]
            {
                var nested: [String: Any] = [:]
                for (nestedKey, nestedValue) in nestedFields {
                    nested[nestedKey] = unwrap(nestedValue)
                }
                return nested
            } else {
                return nil
            }
        }

        var json: [String: Any] = [:]
        for (key, wrapped) in fields {
            json[key] = unwrap(wrapped)
        }

        let data = try JSONSerialization.data(withJSONObject: json, options: [.prettyPrinted])
        let item = try decoder.decode(T.self, from: data)
        Log(item.preetyPrinted)
        return item
    }
}

public extension FirestoreRESTClient {
    private func createFilters(_ filters: [FirestoreFilter]) -> [[String: Any]] {
        filters.map(\.firestoreRepresentation)
    }

    func query<T: Codable & Sendable>(
        collection: FirestoreCollectionPath,
        filters: [FirestoreFilter],
        orderBy: [String]? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        try await runQuery(
            collection: collection.rawValue,
            filters: createFilters(filters),
            orderBy: orderBy,
            limit: limit,
            as: T.self
        )
    }

    func query<T: Codable & Sendable>(
        collection: FirestoreCollectionPath,
        filter: FirestoreFilter,
        orderBy: [String]? = nil,
        limit: Int? = nil
    ) async throws -> [T] {
        try await query(
            collection: collection,
            filters: [filter],
            orderBy: orderBy,
            limit: limit
        )
    }
}
