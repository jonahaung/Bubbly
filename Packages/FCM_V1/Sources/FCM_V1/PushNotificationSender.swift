//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Foundation

public actor PushNotificationSender {
    public enum Error: Swift.Error {
        case invalidURL
        case invalidRequest
        case invalidResponse
        case fcmError(String)
    }

    private enum Constants {
        static let fcmSendPath = "/v1/projects/%@/messages:send"
        static let baseURL = "https://fcm.googleapis.com"
        static let authorizationHeader = "Authorization"
        static let contentTypeHeader = "Content-Type"
        static let jsonContentType = "application/json"
        static let bearerTokenPrefix = "Bearer"
        static let unauthorizedStatusCode = 401
    }

    private let urlSession = URLSession(configuration: .ephemeral)
    private let accessTokenService: AccessTokenService

    public init(suitName: String) {
        accessTokenService = .init(credentials: .shared, suitName: suitName)
    }

    public func send(notification: APNSNotification) async throws -> String {
        let authToken = try await accessTokenService.getAccessToken()
        return try await send(
            notification: notification,
            authToken: authToken,
            allowsTokenRefresh: true
        )
    }

    private func send(
        notification: APNSNotification,
        authToken: String,
        allowsTokenRefresh: Bool
    ) async throws -> String {
        let request = try createRequest(
            for: notification,
            authToken: authToken
        )
        let (data, response) = try await urlSession.data(for: request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw Error.invalidResponse
        }

        if httpResponse.statusCode == Constants.unauthorizedStatusCode, allowsTokenRefresh {
            let refreshedToken = try await accessTokenService.refreshToken()
            return try await send(
                notification: notification,
                authToken: refreshedToken,
                allowsTokenRefresh: false
            )
        }

        return try validate(response: httpResponse, data: data)
    }

    private func createRequest(
        for notification: APNSNotification,
        authToken: String
    ) throws -> URLRequest {
        let projectID = accessTokenService.credentials.projectID.trimmingCharacters(in: .whitespacesAndNewlines)
        let deviceToken = notification.message.token.trimmingCharacters(in: .whitespacesAndNewlines)
        let bearerToken = authToken.trimmingCharacters(in: .whitespacesAndNewlines)

        guard
            !projectID.isEmpty,
            !deviceToken.isEmpty,
            !bearerToken.isEmpty
        else {
            throw Error.invalidRequest
        }

        let urlString = Constants.baseURL + String(
            format: Constants.fcmSendPath,
            projectID
        )

        guard let url = URL(string: urlString) else {
            throw Error.invalidURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(
            "\(Constants.bearerTokenPrefix) \(bearerToken)",
            forHTTPHeaderField: Constants.authorizationHeader
        )
        request.setValue(
            Constants.jsonContentType,
            forHTTPHeaderField: Constants.contentTypeHeader
        )
        request.httpBody = try notification.data()
        return request
    }

    private func validate(response: HTTPURLResponse, data: Data) throws -> String {
        guard (200...299).contains(response.statusCode) else {
            let errorMessage = extractErrorMessage(from: data)
            throw Error.fcmError("HTTP \(response.statusCode): \(errorMessage)")
        }
        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            throw Error.invalidResponse
        }
        guard let string = (json["name"] as? String),
              let lastPath = string.components(separatedBy: "/").last
        else {
            throw Error.invalidResponse
        }
        return lastPath
    }

    private func extractErrorMessage(from data: Data) -> String {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            return "Unknown FCM error"
        }
        if let error = json["error"] as? [String: Any] {
            if let message = error["message"] as? String {
                return message
            }
            if let status = error["status"] as? String {
                return status
            }
        }
        if let error = json["error"] as? String {
            return error
        }
        return "Unknown FCM error"
    }
}
