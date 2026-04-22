//  AnyMsgData+Extensions.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Core
import Foundation

public extension AnyMsgData {
    enum ParseError: Error {
        case missingEncryptedMessage
        case currentUserIDUnavailable
        case invalidDecryptedPayload
    }

    static func parse(from userInfo: [AnyHashable: Any]) throws -> AnyMsgData {
        let encryptedMessage: String
        if let string = userInfo["message"] as? String {
            encryptedMessage = string
        } else if let string = userInfo["message"] as? NSString {
            encryptedMessage = string as String
        } else {
            throw ParseError.missingEncryptedMessage
        }
        let currentUserID = try CurrentUserID.get()
        let decrypted = try CryptoService.shared.decrypt(
            payloadString: encryptedMessage,
            currentUserID: currentUserID
        )

        guard let data = decrypted.data(using: .utf8) else {
            throw ParseError.invalidDecryptedPayload
        }

        return try JSONDecoder().decode(
            AnyMsgData.self,
            from: data
        )
    }
}
