//
//  CryptoService.swift
//  Services
//
//  Created by Aung Ko Min on 16/6/25.
//

import Crypto
import Foundation
import CryptoKit
import Core

public final class CryptoService: Sendable {

	public static let shared = CryptoService()

	public var privateKey: Curve25519.KeyAgreement.PrivateKey {
		let storage = GroupAppStorage.shared
		guard let currentUserId = storage.string(for: .auth(.currentUserID)) else { fatalError() }
		if let string = storage.string(
			for: .security(.privateKey(id: currentUserId))
		) {
			if let privateKey = Crypto.privateKey(with: string) {
				return privateKey
			}
		}
		let newKeyPair = Crypto.newPrivateKeyInstance()
		storage
			.save(
				value: Crypto.base64String(with: newKeyPair),
				for: .security(.privateKey(id: currentUserId))
			)
		storage
			.save(
				value: Crypto.base64String(with: newKeyPair.publicKey),
				for: .security(.publicKey(id: currentUserId))
			)
		return newKeyPair
	}

	public var publicKey: Curve25519.KeyAgreement.PublicKey {
		privateKey.publicKey
	}

	public var privateKeyString: String {
		Crypto.base64String(with: privateKey)
	}

	public var publicKeyString: String {
		Crypto.base64String(with: publicKey)
	}

	private init() {}

	private let salt: Data = Crypto.generateSalt()

	public func createPayload(for encryptedDataString: String) -> String {
		salt.base64EncodedString() + ":" + publicKeyString + ":" + encryptedDataString
	}

	public func parsePayload(_ payloadString: String) -> (salt64: String, publicKeyString: String, encryptedDataString: String)? {
		let components = payloadString.components(separatedBy: ":")
		guard components.count == 3 else { return nil }
		return (components[0], components[1], components[2])
	}
}

public extension CryptoService {
	func encrypt(dataString: String, publicKeyString: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			  let symmetricKey = Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt),
			  let data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(dataString),
			  let encryptedData = Crypto.encrypt(data: data, using: symmetricKey) else {
			return dataString
		}
		return Crypto.encondeForNetworkTransport(encrypted: encryptedData)
	}

	func decrypt(dataString: String, publicKeyString: String, base64Salt: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			  let salt = Data(base64Encoded: base64Salt),
			  let symmetricKey = Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt),
			  let data = Crypto.decodeFromNetworkTransport(string: dataString) else {
			return dataString
		}
		let decryptedData = Crypto.decrypt(encryptedData: data, using: symmetricKey)
		return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? dataString
	}
}
