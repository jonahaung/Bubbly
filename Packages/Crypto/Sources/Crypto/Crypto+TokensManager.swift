//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import CryptoKit
import Foundation

// typealias PublicKeysHotStorage = Crypto.PublicKeysHotStorage
// public extension Crypto {
//    struct PublicKeysHotStorage {
//        private init() {}
//
//        public static func store(publicKey base64String: String, for userID: String) {
//            guard let publicKey = Crypto.publicKey(with: base64String) else { return } // Not a
//            valid public key
//            store(publicKey: publicKey, for: userID)
//        }
//
//        public static func store(publicKey: Curve25519.KeyAgreement.PublicKey, for userID: String)
//        {
//            HotStorage.add(object: publicKey.toBase64String, withKey: userID)
//        }
//
//        public static func get(for userID: String) -> Curve25519.KeyAgreement.PublicKey? {
//            guard let pk64String = HotStorage.get(key: userID),
//                  let pk = Crypto.publicKey(with: pk64String as String)
//            else {
//                return nil
//            }
//            return pk
//        }
//
//        public static func delete(for userID: String) {
//            HotStorage.delete(key: userID)
//        }
//
//        public static func cleanAll() {
//            HotStorage.clean()
//        }
//    }
// }
//
// private struct HotStorage {
//    private init() {}
//
//    private nonisolated(unsafe) static let _cache = NSCache<NSString, NSString>()
//
//    static func add(object: String, withKey: String) {
//        objc_sync_enter(_cache); defer { objc_sync_exit(_cache) }
//        _cache.setObject(object as NSString, forKey: withKey as NSString)
//    }
//
//    static func get(key: String) -> NSString? {
//        objc_sync_enter(_cache); defer { objc_sync_exit(_cache) }
//        if let object = _cache.object(forKey: key as NSString) { return object }
//        return nil
//    }
//
//    static func delete(key: String) {
//        objc_sync_enter(_cache); defer { objc_sync_exit(_cache) }
//        _cache.removeObject(forKey: key as NSString)
//    }
//
//    static func clean() {
//        objc_sync_enter(_cache); defer { objc_sync_exit(_cache) }
//        _cache.removeAllObjects()
//    }
// }
