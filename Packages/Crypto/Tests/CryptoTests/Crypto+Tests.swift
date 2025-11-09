//
//  Created by Aung Ko Min on 10/01/2021.
//

@preconcurrency import Crypto
@preconcurrency import CryptoKit
import Foundation

private struct TestVars {
    private init() {}

    struct AliceSender {
        private init() {}
        static let privateKey = Crypto.newPrivateKeyInstance()
        static let publicKey = privateKey.publicKey
    }

    struct BobReceiver {
        private init() {}
        static let privateKey = Crypto.newPrivateKeyInstance()
        static let publicKey = privateKey.publicKey
    }

    static let salt = "6beab91f-4a1a-4449-96cb-b6e0edb30776".data(using: .utf8)!
    static let secretPlain = "my secret"
    static let secretPlainData = Crypto.humanFriendlyPlainMessageToDataPlainMessage(secretPlain)!
}

extension Crypto {
    //
    // Encrypt and decrypt using shared symmetric key
    //
    static func sampleUsage1() -> Bool {
        print("\n\n\n\n\n\n")
        struct AliceSender {
            private init() {}
            static let privateKey = Crypto.newPrivateKeyInstance()
            static let publicKey = privateKey.publicKey
        }

        struct BobReceiver {
            private init() {}
            static let privateKey = Crypto.newPrivateKeyInstance()
            static let publicKey = privateKey.publicKey
        }

        let salt = "6beab91f-4a1a-4449-96cb-b6e0edb30776".data(using: .utf8)!
        let aliceSecret = "my secret"
        let aliceSecretData = aliceSecret.data(using: .utf8)

        print("aliceSecret: \(aliceSecret)\n")

        // Sender: Generating symmetric key and encrpting data USING shared symmetric key
        let senderSymmetricKey = Crypto.generateSymmetricKeyBetween(AliceSender.privateKey, and: BobReceiver.publicKey, salt: salt)!
        let encryptedData = Crypto.encrypt(data: aliceSecretData!, using: senderSymmetricKey)!

        // Receiver: Generating symmetric key and decrypting data USING shared symmetric key
        let reveiverSymmetricKey = Crypto.generateSymmetricKeyBetween(BobReceiver.privateKey, and: AliceSender.publicKey, salt: salt)!
        let decryptedData = Crypto.decrypt(encryptedData: encryptedData, using: reveiverSymmetricKey)

        let bobSecret = String(data: decryptedData!, encoding: .utf8)!
        print("bobSecret: \(bobSecret)\n")

        // The decripted data, should be equals with the secret
        return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) == TestVars.secretPlain
    }

    //
    // Encrypt and decrypt using shared symmetric key
    //
    static func sampleUsageX() -> Bool {
        // Sender: Generating symmetric key and encrpting data USING shared symmetric key
        let senderSymmetricKey = Crypto.generateSymmetricKeyBetween(TestVars.AliceSender.privateKey, and: TestVars.BobReceiver.publicKey, salt: TestVars.salt)!
        let encryptedData = Crypto.encrypt(data: TestVars.secretPlainData, using: senderSymmetricKey)!

        // Receiver: Generating symmetric key and decrypting data USING shared symmetric key
        let reveiverSymmetricKey = Crypto.generateSymmetricKeyBetween(TestVars.BobReceiver.privateKey, and: TestVars.AliceSender.publicKey, salt: TestVars.salt)!
        let decryptedData = Crypto.decrypt(encryptedData: encryptedData, using: reveiverSymmetricKey)

        // The decripted data, should be equals with the secret
        return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) == TestVars.secretPlain
    }

    //
    // Encrypt and decrypt using shared public and private keys
    //
    static func sampleUsage2() -> Bool {
        // Sender: Generating symmetric key and encrpting data USING public and private keys
        let encryptedData = Crypto.encrypt(data: TestVars.secretPlainData,
                                           sender: TestVars.AliceSender.privateKey,
                                           receiver: TestVars.BobReceiver.publicKey,
                                           salt: TestVars.salt)!

        // Receiver: Generating symmetric key and decrypting data USING public and private keys
        let decryptedData = Crypto.decrypt(encryptedData: encryptedData,
                                           receiver: TestVars.BobReceiver.privateKey,
                                           sender: TestVars.AliceSender.publicKey,
                                           salt: TestVars.salt)

        // The decripted data, should be equals with the secret
        return Crypto.dataPlainMessageToHumanFriendlyPlainMessage(decryptedData) ?? "" == TestVars.secretPlain
    }

    //
    // Test same symetric keys generation with Alice and Bob public and private keys
    //
    static func testSymetricKeysGeneration() -> Bool {
        let senderSymmetricKey = Crypto.generateSymmetricKeyBetween(TestVars.AliceSender.privateKey, and: TestVars.BobReceiver.publicKey, salt: TestVars.salt)!
        let reveiverSymmetricKey = Crypto.generateSymmetricKeyBetween(TestVars.BobReceiver.privateKey, and: TestVars.AliceSender.publicKey, salt: TestVars.salt)!
        return senderSymmetricKey == reveiverSymmetricKey
    }

    //
    // Test
    //
    static func testDataToStringConversions() -> Bool {
        let plainSecretUtf8Data = Crypto.humanFriendlyPlainMessageToDataPlainMessage(TestVars.secretPlain)

        let aliceEncryptedData = Crypto.encrypt(data: plainSecretUtf8Data!,
                                                sender: TestVars.AliceSender.privateKey,
                                                receiver: TestVars.BobReceiver.publicKey,
                                                salt: TestVars.salt)!

        let aliceEncryptedDataOverTheNetwork = Crypto.encondeForNetworkTransport(encrypted: aliceEncryptedData)

        guard let bobEncryptedData = Crypto.decodeFromNetworkTransport(string: aliceEncryptedDataOverTheNetwork) else { return false }

        let bobDecryptedData = Crypto.decrypt(encryptedData: bobEncryptedData,
                                              receiver: TestVars.BobReceiver.privateKey,
                                              sender: TestVars.AliceSender.publicKey,
                                              salt: TestVars.salt)

        let secretPlain = Crypto.dataPlainMessageToHumanFriendlyPlainMessage(bobDecryptedData)
        return secretPlain == TestVars.secretPlain
    }

    //
    // Test conventing public key into base 64 string, and again from base 64 into public key
    //
    static func testPublicKeyToBase64AndThenBackToPublicKey() -> Bool {
        let publicKeyIntoBase64String = Crypto.base64String(with: TestVars.BobReceiver.publicKey)
        let publicKeyFromBase64String = Crypto.publicKey(with: publicKeyIntoBase64String)!
        return publicKeyIntoBase64String == Crypto.base64String(with: publicKeyFromBase64String)
    }

    static func testPublicKeysHotStorage() -> Bool {
        let userId = "\(UUID())"
        let publicKey = Crypto.newPrivateKeyInstance().publicKey

        // Test : After a clean up, no keys should exist
        Crypto.PublicKeysHotStorage.store(publicKey: publicKey.toBase64String, for: userId)
        Crypto.PublicKeysHotStorage.cleanAll()
        guard Crypto.PublicKeysHotStorage.get(for: userId) == nil else { return false }

        // Test : After fetching a stored Public Key, should have the same value that the key that was used to store it
        Crypto.PublicKeysHotStorage.store(publicKey: publicKey.toBase64String, for: userId)
        let storedPublicKey = Crypto.PublicKeysHotStorage.get(for: userId)
        guard storedPublicKey?.toBase64String == publicKey.toBase64String else { return false }

        // Test : Deleting a key
        Crypto.PublicKeysHotStorage.store(publicKey: publicKey.toBase64String, for: userId)
        Crypto.PublicKeysHotStorage.delete(for: userId)
        guard Crypto.PublicKeysHotStorage.get(for: userId) == nil else { return false }

        return true
    }
}
