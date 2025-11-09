//
//  PContact.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 14/7/24.
//

import Foundation
import SwiftData

@Model
public final class PContact: CollectionDocument, SendableDocument {
	@Attribute(.unique)
	public var uid: String
	public var name: String
	public var mobile: String
	public var photoURL: String
	public var pushToken: String
	public var publicKeyString: String
	public var theme: ConversationTheme?
	public var seenMember: SeenMember?
	public var lastMsgID: String?

	init(
		uid: String = String(),
		name: String = String(),
		mobile: String = String(),
		photoURL: String = String(),
		pushToken: String = String(),
		publicKeyString: String = String(),
		theme: ConversationTheme? = nil,
		seenMember: SeenMember? = nil,
		lastMsgID: String? = nil
	) {
		self.uid = uid
		self.name = name
		self.mobile = mobile
		self.photoURL = photoURL
		self.pushToken = pushToken
		self.publicKeyString = publicKeyString
		self.theme = theme
		self.seenMember = seenMember
		self.lastMsgID = lastMsgID
	}
}
