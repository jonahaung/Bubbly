import Crypto
import Foundation
import CryptoKit
import Core
import FirebaseAuth

public final class CryptoService: Sendable {

	public static let shared = CryptoService()

	nonisolated(unsafe)
	private let storage = GroupStorage.shared
	private let salt: Data = Crypto.generateSalt()

	private init() {}
}

// MARK: - Key Management
public extension CryptoService {

	var privateKey: Curve25519.KeyAgreement.PrivateKey {
		guard let currentUserId else {
			fatalError("No current user ID found")
		}

		if let storedKeyString = storage.string(for: .security(.privateKey(id: currentUserId))),
		   let privateKey = Crypto.privateKey(with: storedKeyString) {
			return privateKey
		}

		return generateAndStoreNewKeyPair(for: currentUserId)
	}

	var publicKey: Curve25519.KeyAgreement.PublicKey {
		privateKey.publicKey
	}

	var privateKeyString: String {
		Crypto.base64String(with: privateKey)
	}

	var publicKeyString: String {
		Crypto.base64String(with: publicKey)
	}
}

// MARK: - Payload Handling
public extension CryptoService {

	func createPayload(for encryptedDataString: String) -> String {
		[salt.base64EncodedString(), publicKeyString, encryptedDataString].joined(separator: ":")
	}

	func parsePayload(_ payloadString: String) -> (salt64: String, publicKeyString: String, encryptedDataString: String)? {
		let components = payloadString.components(separatedBy: ":")
		guard components.count == 3 else { return nil }
		return (components[0], components[1], components[2])
	}
}

// MARK: - Encryption & Decryption
public extension CryptoService {

	func encrypt(dataString: String, publicKeyString: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			  let symmetricKey = generateSymmetricKey(with: foreignPublicKey),
			  let data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(dataString),
			  let encryptedData = Crypto.encrypt(data: data, using: symmetricKey) else {
			return dataString
		}
		return Crypto.encondeForNetworkTransport(encrypted: encryptedData)
	}

	func decrypt(dataString: String, publicKeyString: String, base64Salt: String) -> String {
		guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
			  let salt = Data(base64Encoded: base64Salt),
			  let symmetricKey = generateSymmetricKey(with: foreignPublicKey, salt: salt),
			  let encryptedData = Crypto.decodeFromNetworkTransport(string: dataString) else {
			return dataString
		}

		let decryptedData = Crypto.decrypt(encryptedData: encryptedData, using: symmetricKey)
		return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? dataString
	}
}

// MARK: - Private Helpers
private extension CryptoService {

	func generateAndStoreNewKeyPair(for userId: String) -> Curve25519.KeyAgreement.PrivateKey {
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

	func generateSymmetricKey(with foreignPublicKey: Curve25519.KeyAgreement.PublicKey, salt: Data? = nil) -> SymmetricKey? {
		Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt ?? self.salt)
	}
}
