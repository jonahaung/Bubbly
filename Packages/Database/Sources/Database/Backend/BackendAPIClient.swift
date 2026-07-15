import Core
import FirebaseAuth
import Foundation

public actor BackendAPIClient {
    public static let shared = BackendAPIClient()

    private let session: URLSession
    private let encoder: JSONEncoder
    private let decoder: JSONDecoder

    public init(session: URLSession = .shared) {
        self.session = session
        encoder = JSONEncoder()
        decoder = JSONDecoder()
    }

    public func contact(userID: String) async throws -> Contact? {
        let response = try await send(
            method: "GET",
            path: ["v1", "contacts", userID],
            allowsNotFound: true
        )
        guard let data = response else {
            return nil
        }
        return try decode(Contact.self, from: data)
    }

    public func lookupContacts(mobileNumbers: [String]) async throws -> [Contact] {
        let uniqueNumbers = Array(Set(mobileNumbers))
        guard !uniqueNumbers.isEmpty else {
            return []
        }
        var contacts: [Contact] = []
        contacts.reserveCapacity(uniqueNumbers.count)
        var startIndex = uniqueNumbers.startIndex
        while startIndex < uniqueNumbers.endIndex {
            let endIndex = min(startIndex + 500, uniqueNumbers.endIndex)
            let body = try encoder.encode(
                ContactLookupRequest(mobileNumbers: Array(uniqueNumbers[startIndex ..< endIndex]))
            )
            let data = try await requiredResponse(
                method: "POST",
                path: ["v1", "contacts", "lookup"],
                body: body,
                contentType: "application/json"
            )
            contacts.append(contentsOf: try decode([Contact].self, from: data))
            startIndex = endIndex
        }
        return contacts
    }

    public func currentProfile() async throws -> CurrentUserModel? {
        let response = try await send(
            method: "GET",
            path: ["v1", "profile"],
            allowsNotFound: true
        )
        guard let data = response else {
            return nil
        }
        return try decode(CurrentUserModel.self, from: data)
    }

    @discardableResult
    public func updateProfile(_ model: CurrentUserModel) async throws -> CurrentUserModel {
        let body = try encoder.encode(ProfileUpdateRequest(model))
        let data = try await requiredResponse(
            method: "PUT",
            path: ["v1", "profile"],
            body: body,
            contentType: "application/json"
        )
        return try decode(CurrentUserModel.self, from: data)
    }

    public func updatePushToken(_ pushToken: String) async throws {
        let body = try encoder.encode(PushTokenUpdateRequest(pushToken: pushToken))
        _ = try await send(
            method: "PATCH",
            path: ["v1", "profile", "push-token"],
            body: body,
            contentType: "application/json"
        )
    }

    public func uploadProfilePhoto(data: Data, contentType: String) async throws -> URL {
        let response = try await requiredResponse(
            method: "PUT",
            path: ["v1", "profile", "photo"],
            body: data,
            contentType: contentType
        )
        let model = try decode(CurrentUserModel.self, from: response)
        guard let url = URL(string: model.photoURL) else {
            throw BackendAPIError.invalidResponse
        }
        return url
    }

    public func uploadProfilePhoto(fileURL: URL, contentType: String) async throws -> URL {
        let response = try await uploadFile(
            fileURL,
            contentType: contentType,
            forceTokenRefresh: false
        )
        let model = try decode(CurrentUserModel.self, from: response)
        guard let url = URL(string: model.photoURL) else {
            throw BackendAPIError.invalidResponse
        }
        return url
    }

    private func requiredResponse(
        method: String,
        path: [String],
        body: Data? = nil,
        contentType: String? = nil
    ) async throws -> Data {
        guard let data = try await send(
            method: method,
            path: path,
            body: body,
            contentType: contentType
        ) else {
            throw BackendAPIError.invalidResponse
        }
        return data
    }

    private func send(
        method: String,
        path: [String],
        body: Data? = nil,
        contentType: String? = nil,
        allowsNotFound: Bool = false,
        forceTokenRefresh: Bool = false
    ) async throws -> Data? {
        let request = try await makeRequest(
            method: method,
            path: path,
            body: body,
            contentType: contentType,
            forceTokenRefresh: forceTokenRefresh
        )
        let data: Data
        let response: URLResponse
        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch {
            throw error
        }
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200 ..< 300:
            return data
        case 401 where !forceTokenRefresh:
            return try await send(
                method: method,
                path: path,
                body: body,
                contentType: contentType,
                allowsNotFound: allowsNotFound,
                forceTokenRefresh: true
            )
        case 404 where allowsNotFound:
            return nil
        default:
            let errorResponse = try? decoder.decode(BackendErrorResponse.self, from: data)
            throw BackendAPIError.rejected(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.reason ?? ""
            )
        }
    }

    private func makeRequest(
        method: String,
        path: [String],
        body: Data?,
        contentType: String?,
        forceTokenRefresh: Bool
    ) async throws -> URLRequest {
        guard let user = Auth.auth().currentUser else {
            throw BackendAPIError.notAuthenticated
        }
        let token = try await user.getIDTokenResult(forcingRefresh: forceTokenRefresh).token
        let baseURL = try BackendConfiguration.baseURL()
        let url = path.reduce(baseURL) { partialURL, component in
            partialURL.appending(path: component)
        }
        var request = URLRequest(url: url)
        request.httpMethod = method
        request.httpBody = body
        request.timeoutInterval = 30
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        request.setValue("application/json", forHTTPHeaderField: "Accept")
        if let contentType {
            request.setValue(contentType, forHTTPHeaderField: "Content-Type")
        }
        return request
    }

    private func uploadFile(
        _ fileURL: URL,
        contentType: String,
        forceTokenRefresh: Bool
    ) async throws -> Data {
        let request = try await makeRequest(
            method: "PUT",
            path: ["v1", "profile", "photo"],
            body: nil,
            contentType: contentType,
            forceTokenRefresh: forceTokenRefresh
        )
        let (data, response) = try await session.upload(for: request, fromFile: fileURL)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw BackendAPIError.invalidResponse
        }
        switch httpResponse.statusCode {
        case 200 ..< 300:
            return data
        case 401 where !forceTokenRefresh:
            return try await uploadFile(
                fileURL,
                contentType: contentType,
                forceTokenRefresh: true
            )
        default:
            let errorResponse = try? decoder.decode(BackendErrorResponse.self, from: data)
            throw BackendAPIError.rejected(
                statusCode: httpResponse.statusCode,
                message: errorResponse?.reason ?? ""
            )
        }
    }

    private func decode<T: Decodable>(_ type: T.Type, from data: Data) throws -> T {
        do {
            return try decoder.decode(type, from: data)
        } catch {
            throw BackendAPIError.invalidResponse
        }
    }
}
