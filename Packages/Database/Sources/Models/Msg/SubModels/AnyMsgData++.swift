//
//  AnyMsgData++.swift
//  Services
//
//  Created by Aung Ko Min on 24/8/25.
//

import Foundation

public extension AnyMsgData {

	init?(userInfo: [AnyHashable: Any]) {
		guard let string = userInfo["message"] as? String else {
			return nil
		}
		guard let dectypted = Self.decrypt(string) else {
			return nil
		}
		guard let data = dectypted.data(using: .utf8) else {
			return nil
		}
		guard let object = try? JSONDecoder().decode(
			AnyMsgData.self,
			from: data
		) else {
			return nil
		}
		self = object
	}

	private static func decrypt(_ payload: String) -> String? {
		guard let (
			salt64,
			publicKeyString,
			encryptedString
		) = CryptoService.shared.parsePayload(
			payload
		) else {
			return nil
		}
		return CryptoService.shared
			.decrypt(
				dataString: encryptedString,
				publicKeyString: publicKeyString,
				base64Salt: salt64
			)
	}
}
