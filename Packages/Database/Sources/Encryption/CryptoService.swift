//
//  CryptoService.swift
//  Services
//
//  Created by Aung Ko Min on 16/6/25.
//

import Core
import Crypto
import CryptoKit
import FirebaseAuth
import Foundation

struct CryptoPayload: Codable, Sendable {
	let v: Int
	let salt: String
	let publicKey: String
	let ciphertext: String
}
public class CryptoService {

	nonisolated(unsafe)
	public static let shared = CryptoService()

	private init() {}

	// MARK: - Keys

	private var privateKey: Curve25519.KeyAgreement.PrivateKey {
		let storage = GroupStorage.shared
		guard let currentUserId else {
			fatalError("Missing currentUserId")
		}

		if let string = storage.string(
			for: .security(.privateKey(id: currentUserId))),
		   let key = Crypto.privateKey(with: string) {
			return key
		}

		let newKey = Crypto.newPrivateKeyInstance()

		storage.save(
			Crypto.base64String(with: newKey),
			for: .security(.privateKey(id: currentUserId))
		)

		storage.save(
			Crypto.base64String(with: newKey.publicKey),
			for: .security(.publicKey(id: currentUserId))
		)

		return newKey
	}

	var publicKeyString: String {
		Crypto.base64String(with: privateKey.publicKey)
	}
}

public extension CryptoService {

	func encrypt(
		dataString: String,
		recipientPublicKeyString: String
	) throws -> String {

		let salt = Crypto.generateSalt()

		guard
			let foreignPublicKey = Crypto.publicKey(with: recipientPublicKeyString),
			let symmetricKey = Crypto.generateSymmetricKeyBetween(
				privateKey,
				and: foreignPublicKey,
				salt: salt
			),
			let data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(dataString),
			let encryptedData = Crypto.encrypt(data: data, using: symmetricKey)
		else {
			throw CryptoError.encryptionFailed
		}

		let payload = CryptoPayload(
			v: 1,
			salt: salt.base64EncodedString(),
			publicKey: publicKeyString,
			ciphertext: Crypto.encondeForNetworkTransport(encrypted: encryptedData)
		)

		let encoded = try JSONEncoder().encode(payload)
		return encoded.base64EncodedString()
	}
}
public extension CryptoService {

	func decrypt(
		payloadString: String
	) throws -> String {

		guard
			let payloadData = Data(base64Encoded: payloadString),
			let payload = try? JSONDecoder().decode(CryptoPayload.self, from: payloadData),
			payload.v == 1,
			let salt = Data(base64Encoded: payload.salt),
			let foreignPublicKey = Crypto.publicKey(with: payload.publicKey),
			let symmetricKey = Crypto.generateSymmetricKeyBetween(
				privateKey,
				and: foreignPublicKey,
				salt: salt
			),
			let encryptedData = Crypto.decodeFromNetworkTransport(
				string: payload.ciphertext
			)
		else {
			throw CryptoError.decryptionFailed
		}

		let decrypted = Crypto.decrypt(
			encryptedData: encryptedData,
			using: symmetricKey
		)

		guard let message = Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decrypted)
		else {
			throw CryptoError.invalidPlaintext
		}

		return message
	}
}
public enum CryptoError: Error, Sendable {
	case encryptionFailed
	case decryptionFailed
	case invalidPlaintext
}
/*
 public final class CryptoService: Sendable {
 public static let shared = CryptoService()

 public var privateKey: Curve25519.KeyAgreement.PrivateKey {
 let storage = GroupStorage.shared
 guard let currentUserId else { fatalError() }
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
 Crypto.base64String(with: newKeyPair),
 for: .security(.privateKey(id: currentUserId))
 )
 storage
 .save(
 Crypto.base64String(with: newKeyPair.publicKey),
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

 public func parsePayload(
 _ payloadString: String
 ) -> (
 salt64: String,
 publicKeyString: String,
 encryptedDataString: String
 )? {
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
 let encryptedData = Crypto.encrypt(data: data, using: symmetricKey)
 else {
 return dataString
 }
 return Crypto.encondeForNetworkTransport(encrypted: encryptedData)
 }

 func decrypt(dataString: String, publicKeyString: String, base64Salt: String) -> String {
 guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
 let salt = Data(base64Encoded: base64Salt),
 let symmetricKey = Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt),
 let data = Crypto.decodeFromNetworkTransport(string: dataString)
 else {
 return dataString
 }
 let decryptedData = Crypto.decrypt(encryptedData: data, using: symmetricKey)
 return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? dataString
 }
 }
 */


//public final class CryptoService: Sendable {
//    public static let shared = CryptoService()
//
//	private let storage = GroupStorage.shared
//    private let salt: Data = Crypto.generateSalt()
//
//    private init() {}
//}
//
//// MARK: - Key Management
//
//public extension CryptoService {
//    var privateKey: Curve25519.KeyAgreement.PrivateKey {
//        guard let currentUserId else {
//            fatalError("No current user ID found")
//        }
//
//        if let storedKeyString = storage.string(for: .security(.privateKey(id: currentUserId))),
//           let privateKey = Crypto.privateKey(with: storedKeyString) {
//            return privateKey
//        }
//
//        return generateAndStoreNewKeyPair(for: currentUserId)
//    }
//
//    var publicKey: Curve25519.KeyAgreement.PublicKey {
//        privateKey.publicKey
//    }
//
//    var privateKeyString: String {
//        Crypto.base64String(with: privateKey)
//    }
//
//    var publicKeyString: String {
//        Crypto.base64String(with: publicKey)
//    }
//}
//
//// MARK: - Payload Handling
//
//public extension CryptoService {
//    func createPayload(for encryptedDataString: String) -> String {
//        [salt.base64EncodedString(), publicKeyString, encryptedDataString].joined(separator: ":")
//    }
//
//    func parsePayload(_ payloadString: String) -> (salt64: String, publicKeyString: String, encryptedDataString: String)? {
//        let components = payloadString.components(separatedBy: ":")
//        guard components.count == 3 else { return nil }
//        return (components[0], components[1], components[2])
//    }
//}
//
//// MARK: - Encryption & Decryption
//
//public extension CryptoService {
//    func encrypt(dataString: String, publicKeyString: String) -> String {
//        guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
//              let symmetricKey = generateSymmetricKey(with: foreignPublicKey),
//              let data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(dataString),
//              let encryptedData = Crypto.encrypt(data: data, using: symmetricKey)
//        else {
//            return dataString
//        }
//        return Crypto.encondeForNetworkTransport(encrypted: encryptedData)
//    }
//
//    func decrypt(dataString: String, publicKeyString: String, base64Salt: String) -> String {
//        guard let foreignPublicKey = Crypto.publicKey(with: publicKeyString),
//              let salt = Data(base64Encoded: base64Salt),
//              let symmetricKey = generateSymmetricKey(with: foreignPublicKey, salt: salt),
//              let encryptedData = Crypto.decodeFromNetworkTransport(string: dataString)
//        else {
//            return dataString
//        }
//
//        let decryptedData = Crypto.decrypt(encryptedData: encryptedData, using: symmetricKey)
//        return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? dataString
//    }
//}
//
//// MARK: - Private Helpers
//
//private extension CryptoService {
//    func generateAndStoreNewKeyPair(for userId: String) -> Curve25519.KeyAgreement.PrivateKey {
//        let newKeyPair = Crypto.newPrivateKeyInstance()
//
//        storage.save(
//            Crypto.base64String(with: newKeyPair),
//            for: .security(.privateKey(id: userId))
//        )
//        storage.save(
//            Crypto.base64String(with: newKeyPair.publicKey),
//            for: .security(.publicKey(id: userId))
//        )
//
//        return newKeyPair
//    }
//
//    func generateSymmetricKey(with foreignPublicKey: Curve25519.KeyAgreement.PublicKey, salt: Data? = nil) -> SymmetricKey? {
//        Crypto.generateSymmetricKeyBetween(privateKey, and: foreignPublicKey, salt: salt ?? self.salt)
//    }
//}
