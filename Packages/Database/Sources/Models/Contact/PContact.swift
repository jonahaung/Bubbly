//
//  PContact.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 14/7/24.
//

import Foundation
import SwiftData
import XUI

@Model
public final class PContact: CollectionDocument {
	@Attribute(.unique)
	public var uid = String()
	public var name = String()
	public var mobile = String()
	public var photoURL = String()
	public var pushToken = String()
	public var publicKeyString: String?
	public var theme: ConversationTheme? = nil
	public var lastMsgID: String? = nil
	public init(
		uid: String,
		name: String,
		mobile: String,
		photoURL: String,
		pushToken: String,
		publicKeyString: String?,
		theme: ConversationTheme?,
		lastMsgID: String?
	) {
		self.uid = uid
		self.name = name
		self.mobile = mobile
		self.photoURL = photoURL
		self.pushToken = pushToken
		self.publicKeyString = publicKeyString
		self.theme = theme
		self.lastMsgID = lastMsgID
	}
}

extension PContact {
	public func update(with snapshot: Contact) {
		self.name = snapshot.name
		if snapshot.mobile.isWhitespace == false && mobile != snapshot.mobile {
			self.mobile = snapshot.mobile
		}
		if photoURL != snapshot.photoURL {
			self.photoURL = snapshot.photoURL
		}
		if pushToken != snapshot.pushToken {
			self.pushToken = snapshot.pushToken
		}
		if let key = snapshot.publicKeyString,
		   key.isWhitespace == false,
		   publicKeyString != key {
			self.publicKeyString = key
		}
		if lastMsgID != snapshot.lastMsgID {
			lastMsgID = snapshot.lastMsgID
		}
		if theme != snapshot.theme {
			theme = snapshot.theme
		}
	}
}
