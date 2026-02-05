//
//  Created by Aung Ko Min on 10/01/2021.
//

import CryptoKit
import Foundation

// public extension Crypto {
//    fileprivate static func toJSON(some: some Codable) -> String? {
//        guard let data = try? JSONEncoder().encode(some.self) else { return nil }
//        return String(data: data, encoding: .utf8)
//    }
//
//    struct StringRequestBody: Codable {
//        public let secret: String
//        public init(secret: String) {
//            // param [secret] should allready be encrypted
//            self.secret = secret
//        }
//    }
//
//    struct DataRequestBody: Codable {
//        public let secret: Data
//        public init(secret: Data) {
//            // param [secret] should allready be encrypted
//            self.secret = secret
//        }
//    }
// }
//
// public extension Crypto.StringRequestBody {
//    var toJSON: String? { Crypto.toJSON(some: self) }
// }
//
// public extension Crypto.DataRequestBody {
//    var toJSON: String? { Crypto.toJSON(some: self) }
//
//    // Maps a [DataRequestBody] into a [StringRequestBody]
//    var toStringRequestBody: Crypto.StringRequestBody {
//        let secret = Crypto.encondeForNetworkTransport(encrypted: secret)
//        return Crypto.StringRequestBody(secret: secret)
//    }
// }
