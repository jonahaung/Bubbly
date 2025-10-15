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

	public var uid = String()
	public var name = String()
	public var mobile = String()
	public var photoURL = String()
	public var pushToken = String()
	public var publicKeyString: String?

	public init(
		uid: String,
		name: String,
		mobile: String,
		photoURL: String,
		pushToken: String,
		publicKeyString: String?
	) {
		self.uid = uid
		self.name = name
		self.mobile = mobile
		self.photoURL = photoURL
		self.pushToken = pushToken
		self.publicKeyString = publicKeyString
	}
}

extension PContact {
	public func update(with snapshot: ContactSnapshot) {
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
	}
}
