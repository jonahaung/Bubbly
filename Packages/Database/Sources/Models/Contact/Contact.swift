//
//  Contact.swift
//  Models
//
//  Created by Aung Ko Min on 13/7/25.
//

import Foundation

public struct Contact: ContactRepresentable {
	public let uid: String
	public var name: String
	public var photoURL: String
	public var pushToken: String
	public var publicKeyString: String

	public let mobile: String
	public var theme: ConversationTheme?
	public var seenMember: SeenMember?
	public var lastMsgID: String?

	public enum CodingKeys: String, CodingKey {
		case uid
		case name
		case mobile
		case photoURL
		case pushToken
		case publicKeyString
	}

	public var isChatAvailable: Bool { !uid.hasPrefix("+") }
}
