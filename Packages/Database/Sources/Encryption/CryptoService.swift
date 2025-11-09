import Core
import Crypto
import CryptoKit
import FirebaseAuth
import Foundation

public final class CryptoService: Sendable {
	public static let shared = CryptoService()

	private nonisolated(unsafe) let storage = GroupStorage.shared
	private let salt: Data = Crypto.generateSalt()

	private init() {}
}

// MARK: - Key Management

extension CryptoService {
	public var privateKey: Curve25519.KeyAgreement.PrivateKey {
		guard let currentUserId else {
			fatalError("No current user ID found")
		}

		if let storedKeyString = storage.string(for: .security(.privateKey(id: currentUserId))),
			let privateKey = Crypto.privateKey(with: storedKeyString)
		{
			return privateKey
		}

		return generateAndStoreNewKeyPair(for: currentUserId)
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
}

// MARK: - Payload Handling

extension CryptoService {
	public func createPayload(for encryptedDataString: String) -> String {
		[salt.base64EncodedString(), publicKeyString, encryptedDataString].joined(separator: ":")
	}

	public func parsePayload(_ payloadString: String) -> (salt64: String, publicKeyString: String, encryptedDataString: String)? {
		let components = payloadString.components(separatedBy: ":")
		guard components.count == 3 else { return nil }
		return (components[0], components[1], components[2])
	}
}

// MARK: - Encryption & Decryption

extension CryptoService {
	public func encrypt(dataString: String, publicKeyString: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			let symmetricKey = generateSymmetricKey(with: foreignPublicKey),
			let data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(dataString),
			let encryptedData = Crypto.encrypt(data: data, using: symmetricKey)
		else {
			return dataString
		}
		return Crypto.encondeForNetworkTransport(encrypted: encryptedData)
	}

	public func decrypt(dataString: String, publicKeyString: String, base64Salt: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			let salt = Data(base64Encoded: base64Salt),
			let symmetricKey = generateSymmetricKey(with: foreignPublicKey, salt: salt),
			let encryptedData = Crypto.decodeFromNetworkTransport(string: dataString)
		else {
			return dataString
		}

		let decryptedData = Crypto.decrypt(encryptedData: encryptedData, using: symmetricKey)
		return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? dataString
	}
}

// MARK: - Private Helpers

extension CryptoService {
	fileprivate func generateAndStoreNewKeyPair(for userId: String) -> Curve25519.KeyAgreement.PrivateKey {
		let newKeyPair = Crypto.newPrivateKeyInstance()

		storage.save(
			Crypto.base64String(with: newKeyPair),
			for: .security(.privateKey(id: userId))
		)
		storage.save(
			Crypto.base64String(with: newKeyPair.publicKey),
			for: .security(.publicKey(id: userId))
		)

		return newKeyPair
	}

	fileprivate func generateSymmetricKey(with foreignPublicKey: Curve25519.KeyAgreement.PublicKey, salt: Data? = nil) -> SymmetricKey? {
		Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt ?? self.salt)
	}
}
