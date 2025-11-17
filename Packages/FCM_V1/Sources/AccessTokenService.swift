//
//  AccessTokenService.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 10/5/25.
//

import Foundation
import SwiftJWT

public actor AccessTokenService {
    public enum Constants {
        public static let tokenValidityTime: TimeInterval = 3600
        public static let authURL = "https://www.googleapis.com/auth/cloud-platform"
        public static let grantType = "urn:ietf:params:oauth:grant-type:jwt-bearer"
        public static let contentType = "application/x-www-form-urlencoded"
    }

    // MARK: - Properties

    public let credentials: ServiceAccountCredentials
    private let tokenCache: TokenCacheProtocol
    private let urlSession = URLSession(configuration: .ephemeral)

    // MARK: - Initialization

    public init(
        credentials: ServiceAccountCredentials,
        suitName: String
    ) {
        self.credentials = credentials
        tokenCache = UserDefaultsTokenCache(suitName: suitName)
    }

    // MARK: - Public Methods

    public func getAccessToken() async throws -> String {
        if let cachedToken = try tokenCache.getValidToken() {
            return cachedToken
        }
        return try await refreshAccessToken()
    }

    public func refreshAccessToken() async throws -> String {
        let signedJWT = try createSignedJWT()
        let token = try await requestGoogleAccessToken(jwt: signedJWT)
        try tokenCache.cache(
            token: token,
            expirationInterval: Constants.tokenValidityTime
        )
        return token
    }

    public func refreshToken() async throws -> String {
        try tokenCache.invalidateToken()
        return try await refreshAccessToken()
    }

    // MARK: - Private Methods

    private func createSignedJWT() throws -> String {
        let now = Date()
        let claims = JWTClaims(
            iss: credentials.clientEmail,
            scope: Constants.authURL,
            aud: credentials.tokenURI,
            iat: now,
            exp: now.addingTimeInterval(Constants.tokenValidityTime)
        )

        var jwt = JWT(claims: claims)
        let privateKey = try sanitizePrivateKey(credentials.privateKey)
        let jwtSigner = JWTSigner.rs256(privateKey: privateKey)

        return try jwt.sign(using: jwtSigner)
    }

    private func sanitizePrivateKey(_ privateKey: String) throws -> Data {
        let sanitizedKey = privateKey
            .replacingOccurrences(of: "-----BEGIN PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "-----END PRIVATE KEY-----", with: "")
            .replacingOccurrences(of: "\n", with: "")
            .trimmingCharacters(in: .whitespacesAndNewlines)

        guard let keyData = Data(base64Encoded: sanitizedKey) else {
            throw PushNotificationError.invalidPrivateKey
        }
        return keyData
    }

    private func requestGoogleAccessToken(jwt: String) async throws -> String {
        guard let url = URL(string: credentials.tokenURI) else {
            throw PushNotificationError.invalidTokenURL
        }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue(Constants.contentType, forHTTPHeaderField: "Content-Type")

        let bodyParams = [
            "grant_type": Constants.grantType,
            "assertion": jwt,
        ]

        request.httpBody = bodyParams
            .map { "\($0.key)=\($0.value)" }
            .joined(separator: "&")
            .data(using: .utf8)

        let (data, response) = try await urlSession.data(for: request)

        guard let httpResponse = response as? HTTPURLResponse,
              httpResponse.statusCode == 200
        else {
            throw PushNotificationError.tokenGenerationFailed
        }

        do {
            if let json = try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any],
               let accessToken = json["access_token"] as? String
            {
                return accessToken
            } else {
                throw PushNotificationError.tokenDecodingFailed
            }

        } catch {
            throw PushNotificationError.tokenDecodingFailed
        }
    }
}
