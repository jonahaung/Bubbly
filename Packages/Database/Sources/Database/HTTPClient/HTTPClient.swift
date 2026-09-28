//  HTTPClient.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Foundation
import FirebaseAuth

public typealias HTTPAccessTokenProvider = @Sendable (_ forceRefresh: Bool) async throws -> String

public struct HTTPClient: Sendable {
    public static let shared: HTTPClient = .init()

    let executor: HTTPRequestExecutor

    public init(session: URLSession = HTTPClient.makeSession()) {
        executor = HTTPRequestExecutor(
            configurationProvider: HTTPClientConfiguration.application,
            accessTokenProvider: HTTPClient.firebaseAccessToken,
            transport: URLSessionBackendHTTPTransport(session: session)
        )
    }

    public init(
        configuration: HTTPClientConfiguration,
        session: URLSession = HTTPClient.makeSession(),
        accessTokenProvider: @escaping HTTPAccessTokenProvider
    ) {
        executor = HTTPRequestExecutor(
            configurationProvider: { configuration },
            accessTokenProvider: accessTokenProvider,
            transport: URLSessionBackendHTTPTransport(session: session)
        )
    }

    init(
        configuration: HTTPClientConfiguration,
        transport: any HTTPTransport,
        accessTokenProvider: @escaping HTTPAccessTokenProvider
    ) {
        executor = HTTPRequestExecutor(
            configurationProvider: { configuration },
            accessTokenProvider: accessTokenProvider,
            transport: transport
        )
    }

    public static func makeSession() -> URLSession {
        let configuration = URLSessionConfiguration.default
        configuration.waitsForConnectivity = false
        configuration.timeoutIntervalForRequest = 30
        configuration.timeoutIntervalForResource = 60
        configuration.httpMaximumConnectionsPerHost = 8
        configuration.requestCachePolicy = .reloadIgnoringLocalCacheData
        configuration.urlCache = nil
        return URLSession(configuration: configuration)
    }

    private static func firebaseAccessToken(forceRefresh: Bool) async throws -> String {
        guard let user = Auth.auth().currentUser else {
            throw HTTPError.notAuthenticated
        }
        return try await user.getIDTokenResult(forcingRefresh: forceRefresh).token
    }
}
