//
//  TokenCacheProtocol.swift
//  FCM_V1
//
//  Created by Aung Ko Min on 10/5/25.
//

import Foundation

// MARK: - Token Caching Protocol
public protocol TokenCacheProtocol {
	func getValidToken() throws -> String?
	func cache(token: String, expirationInterval: TimeInterval) throws
	func invalidateToken() throws
}

// MARK: - UserDefaults Cache Implementation
public struct UserDefaultsTokenCache: TokenCacheProtocol {
	private let storage: UserDefaults

	public enum Constants {
		public static let accessTokenKey = "accessToken"
		public static let accessTokenExpirationKey = "accessTokenExpiration"
	}

	public init(suitName: String) {
		self.storage = .init(suiteName: suitName) ?? .standard
	}

	public func getValidToken() throws -> String? {
		guard let token = storage.string(forKey: Constants.accessTokenKey) else {
			return nil
		}

		let expirationTimestamp = storage.double(forKey: Constants.accessTokenExpirationKey)
		let expirationDate = Date(timeIntervalSince1970: expirationTimestamp)

		return Date() < expirationDate ? token : nil
	}

	public func cache(token: String, expirationInterval: TimeInterval) throws {
		let expirationDate = Date().addingTimeInterval(expirationInterval)
		storage.set(token, forKey: Constants.accessTokenKey)
		storage.set(expirationDate.timeIntervalSince1970, forKey: Constants.accessTokenExpirationKey)
	}

	public func invalidateToken() throws {
		storage.removeObject(forKey: Constants.accessTokenKey)
		storage.removeObject(forKey: Constants.accessTokenExpirationKey)
	}
}
