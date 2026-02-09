//
//  AnyMsgData+Extensions.swift
//  Services
//
//  Created by Aung Ko Min on 24/8/25.
//

import Core
import Foundation

public extension AnyMsgData {
	static func parse(from userInfo: [AnyHashable: Any]) throws -> AnyMsgData? {
		guard let string = userInfo["message"] as? String,
		      let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID))
		else {
			return nil
		}
		let decrypted = try CryptoService.shared.decrypt(
			payloadString: string,
			currentUserID: currentUserID
		)
		guard let data = decrypted.data(using: .utf8) else {
			return nil
		}
		return try JSONDecoder().decode(
			AnyMsgData.self,
			from: data
		)
	}
}
