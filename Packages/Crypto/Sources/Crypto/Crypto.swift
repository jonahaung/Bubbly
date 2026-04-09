//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import CryptoKit
import Foundation

public struct Crypto {
    private init() {}

    public static func newPrivateKeyInstance() -> Curve25519.KeyAgreement.PrivateKey {
        Curve25519.KeyAgreement.PrivateKey()
    }
}

public extension Crypto {
    static func generateSalt(length: Int = 16) -> Data {
        var salt = [UInt8](repeating: 0, count: length)
        let status = SecRandomCopyBytes(kSecRandomDefault, length, &salt)
        precondition(status == errSecSuccess, "Failed to generate secure random bytes")
        return Data(salt)
    }

    static func generateSymmetricKeyBetween(
        _ privateKey: Curve25519.KeyAgreement.PrivateKey,
        and publicKey: Curve25519.KeyAgreement.PublicKey,
        salt: Data = generateSalt()
    ) -> SymmetricKey? {
        guard let sharedSecret = generateSecretBetween(privateKey, and: publicKey)
        else { return nil }
        return sharedSecret.hkdfDerivedSymmetricKey(
            using: SHA256.self,
            salt: salt,
            sharedInfo: Data(),
            outputByteCount: 32
        )
    }

    // data: Data -> utf8 format, salt: Data -> utf8 format
    static func encrypt(data: Data, using symmetricKey: SymmetricKey) -> Data? {
        do {
            return try ChaChaPoly.seal(data, using: symmetricKey).combined
        } catch {
            return nil
        }
    }

    // data: Data -> utf8 format, salt: Data -> utf8 format
    static func encrypt(
        data: Data,
        sender: Curve25519.KeyAgreement.PrivateKey,
        receiver: Curve25519.KeyAgreement.PublicKey,
        salt: Data = generateSalt()
    ) -> Data? {
        guard let symmetricKey = generateSymmetricKeyBetween(sender, and: receiver, salt: salt)
        else { return nil }
        return encrypt(data: data, using: symmetricKey)
    }

    static func decrypt(encryptedData: Data, using symmetricKey: SymmetricKey) -> Data? {
        guard let sealedBox = try? ChaChaPoly.SealedBox(combined: encryptedData),
              let decryptedData = try? ChaChaPoly.open(sealedBox, using: symmetricKey)
        else {
            return nil
        }
        return decryptedData
    }

    static func decrypt(
        encryptedData: Data,
        receiver: Curve25519.KeyAgreement.PrivateKey,
        sender: Curve25519.KeyAgreement.PublicKey,
        salt: Data
    ) -> Data? {
        guard let symmetricKey = generateSymmetricKeyBetween(receiver, and: sender, salt: salt)
        else { return nil }
        return decrypt(encryptedData: encryptedData, using: symmetricKey)
    }
}

//
// MARK: - PublicKey conversion utils

//

public extension Crypto {
    static func base64String(publicKey: Curve25519.KeyAgreement.PublicKey) -> String {
        publicKey.rawRepresentation.base64EncodedString(
            options: Data.Base64EncodingOptions(rawValue: 0)
        )
    }

    static func base64String(privateKey: Curve25519.KeyAgreement.PrivateKey) -> String {
        privateKey.rawRepresentation.base64EncodedString(
            options: Data.Base64EncodingOptions(rawValue: 0)
        )
    }

    static func publicKey(with base64String: String) -> Curve25519.KeyAgreement.PublicKey? {
        guard let data = Data(base64Encoded: base64String),
              let publicKey = try? Curve25519.KeyAgreement.PublicKey(rawRepresentation: data)
        else {
            return nil
        }
        return publicKey
    }
}

//
// MARK: - Private conversion utils

//

public extension Crypto {
    static func base64String(with privateKey: Curve25519.KeyAgreement.PrivateKey) -> String {
        privateKey.rawRepresentation.base64EncodedString(
            options: Data.Base64EncodingOptions(rawValue: 0)
        )
    }

    static func privateKey(with base64String: String) -> Curve25519.KeyAgreement.PrivateKey? {
        guard let data = Data(base64Encoded: base64String),
              let privateKey = try? Curve25519.KeyAgreement.PrivateKey(rawRepresentation: data)
        else {
            return nil
        }
        return privateKey
    }
}

//
// MARK: - Human friendly conversion utils

//

public extension Crypto {
    static func humanFriendlyPlainMessageToDataPlainMessage(_ string: String?) -> Data? {
        guard let string else { return nil }
        return string.data(using: .utf8)
    }

    static func dataPlainMessageToHumanFriendlyPlainMessage(_ data: Data?) -> String? {
        guard let data else { return nil }
        return String(data: data, encoding: .utf8)
    }
}

//
// MARK: - Network conversion utils

//

public extension Crypto {
    /// Receives encrypted Data, and converts into a String so it can be stored or sent over the
    /// network
    static func encondeForNetworkTransport(encrypted: Data) -> String {
        encrypted.base64EncodedString(
            options: Data.Base64EncodingOptions(rawValue: 0)
        )
    }

    /// Receives an encrypted String, and converts into encrypted Data
    static func decodeFromNetworkTransport(string: String?) -> Data? {
        guard string != nil else { return nil }
        return Data(base64Encoded: string!)
    }
}

//
// MARK: - Private

//

private extension Crypto {
    static func generateSecretBetween(
        _ privateKey: Curve25519.KeyAgreement.PrivateKey,
        and publicKey: Curve25519.KeyAgreement
            .PublicKey
    ) -> SharedSecret? {
        try? privateKey.sharedSecretFromKeyAgreement(with: publicKey)
    }
}
