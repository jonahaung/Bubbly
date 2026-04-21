// © 2026 Aung Ko Min

import Core
import FirebaseAuth
import Foundation
import XUI

// MARK: - FirestoreRESTClient

@NetworkActor
public final class FirestoreRESTClient {
    public enum FirestoreError: Error {
        case invalidURL
        case invalidResponse
        case networkError(Error)
        case serverError(String)
        case notAuthenticated
        case encodingError(Error)
        case decodingError(Error)
    }

    private let baseURL: String
    private let decoder: JSONDecoder
    private let encoder: JSONEncoder
    private let timestampFormatterWithFractional: ISO8601DateFormatter
    private let timestampFormatter: ISO8601DateFormatter

    public init(
        projectId: String = AppInformation.firebaseProjectID,
        database: String = "(default)",
    ) {
        baseURL = "https://firestore.googleapis.com/v1/projects/\(projectId)/databases/\(database)/documents"
        decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        timestampFormatterWithFractional = ISO8601DateFormatter()
        timestampFormatterWithFractional.formatOptions = [
            .withInternetDateTime,
            .withFractionalSeconds,
        ]
        timestampFormatter = ISO8601DateFormatter()
        timestampFormatter.formatOptions = [.withInternetDateTime]
    }

    private func performRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil,
        retry: Bool = false,
        token: String? = nil,
    ) async throws -> [String: Any] {
        let result = try await performRawRequest(
            url: url,
            method: method,
            body: body,
            retry: retry,
            token: token,
        )
        guard let json = result as? [String: Any] else {
            throw FirestoreError.invalidResponse
        }

        return json
    }

    private func performRawRequest(
        url: URL,
        method: String,
        body: [String: Any]? = nil,
        retry: Bool = false,
        token: String? = nil,
    ) async throws -> Any {
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.timeoutInterval = 30
        if let token {
            request.addValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }

        request.addValue("application/json", forHTTPHeaderField: "Accept")
        request.addValue("application/json", forHTTPHeaderField: "Content-Type")
        if let body {
            request.httpBody = try JSONSerialization.data(withJSONObject: body)
        }

        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await URLSession.shared.data(for: request)
        } catch {
            throw FirestoreError.networkError(error)
        }
        guard let http = response as? HTTPURLResponse else {
            throw FirestoreError.invalidResponse
        }

        switch http.statusCode {
        case 200 ..< 300:
            if data.isEmpty {
                return [:]
            }
            return try JSONSerialization.jsonObject(with: data)
        case 401 where retry:
            let token = try await getValidAuthToken(forceRefresh: true)
            return try await performRawRequest(
                url: url,
                method: method,
                body: body,
                retry: false,
                token: token,
            )
        default:
            throw FirestoreError.serverError(errorMessage(from: data))
        }
    }

    public func getDocument<T: Codable>(at path: String, as _: T.Type) async throws -> T {
        let token = try await getValidAuthToken()
        let url = try makeDocumentURL(path: path)
        let json = try await performRequest(
            url: url,
            method: "GET",
            retry: true,
            token: token,
        )
        guard let fields = json["fields"] as? [String: Any] else {
            throw FirestoreError.invalidResponse
        }

        return try decodeFirestoreDocument(fields: fields, as: T.self)
    }

    public func createDocument(
        in collectionPath: String,
        documentID: String,
        data: some Codable,
    ) async throws {
        let token = try await getValidAuthToken()
        let url = try makeCreateDocumentURL(
            collectionPath: collectionPath,
            documentID: documentID,
        )
        let payload: [String: Any]
        do {
            payload = try makeDocumentPayload(from: data)
        } catch {
            throw FirestoreError.encodingError(error)
        }
        _ = try await performRequest(
            url: url,
            method: "POST",
            body: payload,
            retry: true,
            token: token,
        )
    }

    public func update(
        value: [String: Any],
        collectionPath: String,
        to documentID: String,
    ) async throws {
        let token = try await getValidAuthToken()
        let payload: [String: Any]
        do {
            payload = try ["fields": makeFirestoreFields(from: value)]
        } catch {
            throw FirestoreError.encodingError(error)
        }
        let url = try makeUpdateDocumentURL(
            path: "\(collectionPath)/\(documentID)",
            fieldPaths: payload.firestoreFieldPaths,
        )
        _ = try await performRequest(
            url: url,
            method: "PATCH",
            body: payload,
            retry: true,
            token: token,
        )
    }

    public func setDocument(
        _ data: some Codable,
        collectionPath: String,
        documentID: String,
    ) async throws {
        let token = try await getValidAuthToken()
        let payload: [String: Any]
        do {
            payload = try makeDocumentPayload(from: data)
        } catch {
            throw FirestoreError.encodingError(error)
        }
        let url = try makeUpdateDocumentURL(
            path: "\(collectionPath)/\(documentID)",
            fieldPaths: payload.firestoreFieldPaths,
        )
        _ = try await performRequest(
            url: url,
            method: "PATCH",
            body: payload,
            retry: true,
            token: token,
        )
    }

    private func runQuery<T: Codable>(
        collection: String,
        filters: [[String: Any]] = [],
        orderBy: [String]? = nil,
        limit: Int? = nil,
        as _: T.Type,
        retry: Bool = true,
        token: String? = nil,
    ) async throws -> [T] {
        let url = try makeRunQueryURL()

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
            structuredQuery["orderBy"] = orderBy.map { [
                "field": ["fieldPath": $0],
                "direction": "ASCENDING",
            ]
            }
        }

        if let limit {
            structuredQuery["limit"] = limit
        }

        let body = ["structuredQuery": structuredQuery]
        let authToken: String =
            if let token {
                token
            } else {
                try await getValidAuthToken(forceRefresh: false)
            }
        let raw = try await performRawRequest(
            url: url,
            method: "POST",
            body: body,
            retry: retry,
            token: authToken,
        )
        if let jsonArray = raw as? [[String: Any]] {
            return try jsonArray.compactMap { item -> T? in
                guard let document = item["document"] as? [String: Any],
                      let fields = document["fields"] as? [String: Any] else
                {
                    return nil
                }

                return try decodeFirestoreDocument(fields: fields, as: T.self)
            }
        }
        if let jsonObject = raw as? [String: Any] {
            if let document = jsonObject["document"] as? [String: Any],
               let fields = document["fields"] as? [String: Any]
            {
                return try [decodeFirestoreDocument(fields: fields, as: T.self)]
            }
            return []
        }
        return []
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
        as _: T.Type,
    ) throws -> T {
        func unwrap(_ value: Any) -> Any? {
            guard let field = value as? [String: Any] else {
                return nil
            }

            if let stringValue = field["stringValue"] as? String {
                return stringValue
            } else if let intString = field["integerValue"] as? String,
                      let intVal = Int(intString)
            {
                return intVal
            } else if let doubleValue = field["doubleValue"] as? Double {
                return doubleValue
            } else if let doubleString = field["doubleValue"] as? String,
                      let doubleValue = Double(doubleString)
            {
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
                var nested = [String: Any]()
                for (nestedKey, nestedValue) in nestedFields {
                    nested[nestedKey] = unwrap(nestedValue)
                }
                return nested
            } else {
                return nil
            }
        }

        var json = [String: Any]()
        for (key, wrapped) in fields {
            json[key] = unwrap(wrapped)
        }

        let data = try JSONSerialization.data(withJSONObject: json)
        do {
            return try decoder.decode(T.self, from: data)
        } catch {
            throw FirestoreError.decodingError(error)
        }
    }

    private func makeDocumentURL(path: String) throws -> URL {
        let encodedPath = path
            .split(separator: "/", omittingEmptySubsequences: true)
            .map { segment in
                String(segment)
                    .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ??
                    String(segment)
            }
            .joined(separator: "/")
        guard let url = URL(string: "\(baseURL)/\(encodedPath)") else {
            throw FirestoreError.invalidURL
        }

        return url
    }

    private func makeCreateDocumentURL(
        collectionPath: String,
        documentID: String,
    ) throws -> URL {
        let components = collectionPath
            .split(separator: "/", omittingEmptySubsequences: true)
            .map(String.init)
        guard let collectionID = components.last else {
            throw FirestoreError.invalidURL
        }

        let parentPath = components.dropLast().joined(separator: "/")
        let encodedCollectionID = collectionID
            .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? collectionID
        let basePath: String
        if parentPath.isEmpty {
            basePath = baseURL
        } else {
            let encodedParent = parentPath
                .split(separator: "/", omittingEmptySubsequences: true)
                .map { segment in
                    let value = String(segment)
                    return value
                        .addingPercentEncoding(withAllowedCharacters: .urlPathAllowed) ?? value
                }
                .joined(separator: "/")
            basePath = "\(baseURL)/\(encodedParent)"
        }
        guard var urlComponents = URLComponents(string: "\(basePath)/\(encodedCollectionID)") else {
            throw FirestoreError.invalidURL
        }

        urlComponents.queryItems = [URLQueryItem(name: "documentId", value: documentID)]
        guard let url = urlComponents.url else {
            throw FirestoreError.invalidURL
        }

        return url
    }

    private func makeUpdateDocumentURL(
        path: String,
        fieldPaths: [String],
    ) throws -> URL {
        let documentURL = try makeDocumentURL(path: path)
        guard var components = URLComponents(url: documentURL, resolvingAgainstBaseURL: false) else {
            throw FirestoreError.invalidURL
        }

        var queryItems = [URLQueryItem(name: "currentDocument.exists", value: "true")]
        queryItems.append(contentsOf: fieldPaths.map { URLQueryItem(
            name: "updateMask.fieldPaths",
            value: $0,
        ) 
        })
        components.queryItems = queryItems
        guard let url = components.url else {
            throw FirestoreError.invalidURL
        }

        return url
    }

    private func makeDocumentPayload(from data: some Codable) throws -> [String: Any] {
        let encoded: Data
        do {
            encoded = try encoder.encode(data)
        } catch {
            throw FirestoreError.encodingError(error)
        }
        let rawObject: Any
        do {
            rawObject = try JSONSerialization.jsonObject(with: encoded)
        } catch {
            throw FirestoreError.encodingError(error)
        }
        guard let dictionary = rawObject as? [String: Any] else {
            throw FirestoreError.invalidResponse
        }

        return try ["fields": makeFirestoreFields(from: dictionary)]
    }

    private func makeFirestoreFields(from dictionary: [String: Any]) throws -> [String: Any] {
        var fields = [String: Any]()
        fields.reserveCapacity(dictionary.count)
        for (key, value) in dictionary {
            fields[key] = try makeFirestoreValue(value)
        }
        return fields
    }

    private func makeFirestoreValue(_ value: Any) throws -> [String: Any] {
        if value is NSNull {
            return ["nullValue": NSNull()]
        }
        if let boolValue = value as? Bool {
            return ["booleanValue": boolValue]
        }
        if let number = value as? NSNumber {
            if CFGetTypeID(number) == CFBooleanGetTypeID() {
                return ["booleanValue": number.boolValue]
            }
            let type = String(cString: number.objCType)
            if type == "f" || type == "d" {
                return ["doubleValue": number.doubleValue]
            }
            if number.doubleValue.rounded(.towardZero) == number.doubleValue {
                return ["integerValue": String(number.int64Value)]
            }
            return ["doubleValue": number.doubleValue]
        }
        if let stringValue = value as? String {
            if isISO8601Timestamp(stringValue) {
                return ["timestampValue": stringValue]
            }
            return ["stringValue": stringValue]
        }
        if let arrayValue = value as? [Any] {
            let values = try arrayValue.map { try makeFirestoreValue($0) }
            if values.isEmpty {
                return ["arrayValue": [:]]
            }
            return ["arrayValue": ["values": values]]
        }
        if let mapValue = value as? [String: Any] {
            return try ["mapValue": ["fields": makeFirestoreFields(from: mapValue)]]
        }
        throw FirestoreError.invalidResponse
    }

    private func isISO8601Timestamp(_ value: String) -> Bool {
        timestampFormatterWithFractional.date(from: value) != nil
            || timestampFormatter.date(from: value) != nil
    }

    private func makeRunQueryURL() throws -> URL {
        guard let url = URL(string: "\(baseURL):runQuery") else {
            throw FirestoreError.invalidURL
        }

        return url
    }

    private func errorMessage(from data: Data) -> String {
        if let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
           let error = json["error"] as? [String: Any],
           let message = error["message"] as? String
        {
            return message
        }
        if let message = String(data: data, encoding: .utf8), !message.isEmpty {
            return message
        }
        return "Unknown server error"
    }
}

private extension [String: Any] {
    var firestoreFieldPaths: [String] {
        let fields = self["fields"] as? [String: Any] ?? [:]
        return fields.keys.sorted()
    }
}

// MARK: - FirestoreRESTClient.FirestoreError + LocalizedError

extension FirestoreRESTClient.FirestoreError: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .invalidURL:
            "Firestore request URL is invalid."
        case .invalidResponse:
            "Firestore returned a response the client could not interpret."
        case let .networkError(error):
            "Firestore network request failed: \(error.localizedDescription)"
        case let .serverError(message):
            "Firestore server error: \(message)"
        case .notAuthenticated:
            "Firestore request requires an authenticated Firebase user."
        case let .encodingError(error):
            "Firestore request encoding failed: \(error.localizedDescription)"
        case let .decodingError(error):
            "Firestore response decoding failed: \(error.localizedDescription)"
        }
    }
}

// MARK: - FirestoreRESTClient.FirestoreError + CustomStringConvertible

extension FirestoreRESTClient.FirestoreError: CustomStringConvertible {
    public var description: String {
        errorDescription ?? String(describing: self)
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
        limit: Int? = nil,
    ) async throws -> [T] {
        try await runQuery(
            collection: collection.rawValue,
            filters: createFilters(filters),
            orderBy: orderBy,
            limit: limit,
            as: T.self,
        )
    }

    func query<T: Codable & Sendable>(
        collection: FirestoreCollectionPath,
        filter: FirestoreFilter,
        orderBy: [String]? = nil,
        limit: Int? = nil,
    ) async throws -> [T] {
        try await query(
            collection: collection,
            filters: [filter],
            orderBy: orderBy,
            limit: limit,
        )
    }
}
