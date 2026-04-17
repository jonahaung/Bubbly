// © 2026 Aung Ko Min

import Core
import Crypto
import CryptoKit
import Foundation

struct CryptoPayload: Codable, Sendable {
    let v: Int
    let salt: String
    let publicKey: String
    let ciphertext: String
}

public final class CryptoService: @unchecked Sendable {
    public static let shared: CryptoService = .init()

    private let lock = NSLock()

    private init() {}

    @discardableResult
    private func getPrivateKey(for userID: String) -> Curve25519.KeyAgreement.PrivateKey {
        withLock {
            let storage = GroupStorage.shared
            if let privateKey = getCachedPrivateKey(userID: userID, storage: storage) {
                persistPublicKeyIfNeeded(for: userID, privateKey: privateKey, storage: storage)
                return privateKey
            }
            return makeNewPrivateKey(userID: userID, storage: storage)
        }
    }

    private func getCachedPrivateKey(
        userID: String,
        storage: GroupStorage
    ) -> Curve25519.KeyAgreement.PrivateKey? {
        guard let base64String = storage.string(for: .security(.privateKey(id: userID))) else {
            return nil
        }
        guard let privateKey = Crypto.privateKey(with: base64String) else {
            storage.delete(for: .security(.privateKey(id: userID)))
            storage.delete(for: .security(.publicKey(id: userID)))
            return nil
        }
        return privateKey
    }

    private func persistPublicKeyIfNeeded(
        for userID: String,
        privateKey: Curve25519.KeyAgreement.PrivateKey,
        storage: GroupStorage
    ) {
        let publicKeyString = Crypto.base64String(publicKey: privateKey.publicKey)
        if storage.string(for: .security(.publicKey(id: userID))) != publicKeyString {
            storage.save(publicKeyString, for: .security(.publicKey(id: userID)))
        }
    }

    private func makeNewPrivateKey(
        userID: String,
        storage: GroupStorage
    ) -> Curve25519.KeyAgreement.PrivateKey {
        let privateKey = Crypto.newPrivateKeyInstance()
        storage.save(
            Crypto.base64String(privateKey: privateKey),
            for: .security(.privateKey(id: userID))
        )
        storage.save(
            Crypto.base64String(publicKey: privateKey.publicKey),
            for: .security(.publicKey(id: userID))
        )
        return privateKey
    }

    private func withLock<T>(_ body: () throws -> T) rethrows -> T {
        lock.lock()
        defer { lock.unlock() }
        return try body()
    }
}

public extension CryptoService {
    func base64PublicKeyString(for userID: String) -> String {
        Crypto.base64String(publicKey: getPrivateKey(for: userID).publicKey)
    }

    func forceReload(for userID: String) {
        withLock {
            let storage = GroupStorage.shared
            storage.delete(for: .security(.privateKey(id: userID)))
            storage.delete(for: .security(.publicKey(id: userID)))
            _ = makeNewPrivateKey(userID: userID, storage: storage)
        }
    }
}

public extension CryptoService {
    func encrypt(
        dataString: String,
        recipientPublicKeyString: String,
        currentUserID: String,
    ) throws -> String {
        let salt = Crypto.generateSalt()

        guard
            let foreignPublicKey = Crypto.publicKey(with: recipientPublicKeyString),
            let symmetricKey = Crypto.generateSymmetricKeyBetween(
                getPrivateKey(for: currentUserID),
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
            publicKey: base64PublicKeyString(for: currentUserID),
            ciphertext: Crypto.encondeForNetworkTransport(encrypted: encryptedData)
        )

        return try JSONEncoder().encode(payload).base64EncodedString()
    }

    func decrypt(
        payloadString: String,
        currentUserID: String,
    ) throws -> String {
        guard let payloadData = Data(base64Encoded: payloadString) else {
            throw CryptoError.decryptionFailed
        }

        let payload: CryptoPayload
        do {
            payload = try JSONDecoder().decode(CryptoPayload.self, from: payloadData)
        } catch {
            throw CryptoError.decryptionFailed
        }

        guard
            payload.v == 1,
            let salt = Data(base64Encoded: payload.salt),
            let foreignPublicKey = Crypto.publicKey(with: payload.publicKey),
            let symmetricKey = Crypto.generateSymmetricKeyBetween(
                getPrivateKey(for: currentUserID),
                and: foreignPublicKey,
                salt: salt
            ),
            let encryptedData = Crypto.decodeFromNetworkTransport(string: payload.ciphertext),
            let decrypted = Crypto.decrypt(
                encryptedData: encryptedData,
                using: symmetricKey
            )
        else {
            throw CryptoError.decryptionFailed
        }

        guard let message = Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decrypted) else {
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
