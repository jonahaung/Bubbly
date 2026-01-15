//
//  AnyMsgData++.swift
//  Services
//
//  Created by Aung Ko Min on 24/8/25.
//

import Foundation

extension AnyMsgData {
	public static func parse(from userInfo: [AnyHashable: Any]) throws -> AnyMsgData? {
		guard let string = userInfo["message"] as? String else {
			return nil
		}
		let decrypted = try CryptoService.shared.decrypt(payloadString: string)
		guard let data = decrypted.data(using: .utf8) else {
			return nil
		}
		return try JSONDecoder().decode(
			AnyMsgData.self,
			from: data
		)
	}
}
