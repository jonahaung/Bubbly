//
//  PushNotificationSender.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 10/5/25.
//

import Foundation

public actor PushNotificationSender {
	// MARK: - Nested Types

	public enum Error: Swift.Error {
		case invalidURL
		case invalidResponse
		case serializationError
		case fcmError(String)
	}

	private enum Constants {
		static let fcmSendPath = "/v1/projects/%@/messages:send"
		static let baseURL = "https://fcm.googleapis.com"
		static let authorizationHeader = "Authorization"
		static let contentTypeHeader = "Content-Type"
		static let jsonContentType = "application/json"
		static let bearerTokenPrefix = "Bearer"
	}

	// MARK: - Properties

	private let urlSession = URLSession(configuration: .ephemeral)
	private let accessTokenService: AccessTokenService

	// MARK: - Initialization

	public init(suitName: String) {
		accessTokenService = .init(credentials: .shared, suitName: suitName)
	}

	// MARK: - Public Methods

	public func send(notification: APNSNotification) async throws -> String {
		let authToken = try await accessTokenService.getAccessToken()
		let request = try createRequest(
			for: notification,
			authToken: authToken
		)
		let (data, response) = try await urlSession.data(for: request)
		guard let httpResponse = response as? HTTPURLResponse else {
			throw Error.invalidResponse
		}
		return try validate(response: httpResponse, data: data)
	}

	// MARK: - Private Methods

	private func createRequest(for notification: APNSNotification,
	                           authToken: String) throws -> URLRequest
	{
		let urlString = Constants.baseURL + String(
			format: Constants.fcmSendPath,
			accessTokenService.credentials.projectID
		)

		guard let url = URL(string: urlString) else {
			throw Error.invalidURL
		}

		var request = URLRequest(url: url)
		request.httpMethod = "POST"
		request.setValue(
			"\(Constants.bearerTokenPrefix) \(authToken)",
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
		guard (200 ... 299).contains(response.statusCode) else {
			let errorMessage = extractErrorMessage(from: data)
			throw Error.fcmError(errorMessage)
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
		guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
		      let error = json["error"] as? String
		else {
			return "Unknown FCM error"
		}
		return error
	}
}
