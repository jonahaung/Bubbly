//
//  ContactSnapshot.swift
//  Models
//
//  Created by Aung Ko Min on 13/7/25.
//

import Contacts
import PhoneNumberKit
import XUI

public struct Contact: Codable, Sendable, Hashable, UIdentifiable {

	public let uid: String
	public var name: String
	public let mobile: String
	public var photoURL: String
	public var pushToken: String
	public var publicKeyString: String?
	public var theme: ConversationTheme?
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
	enum CodingKeys: String, CodingKey {
		case uid
		case name
		case mobile
		case photoURL
		case pushToken
		case publicKeyString
		case lastMsgID
	}
	public init?(cnContact: CNContact) {
		let name = cnContact.givenName.isEmpty ?
		[cnContact.middleName, cnContact.familyName].joined(separator: " ").trimmed :
		cnContact.givenName.trimmed
		guard !name.isWhitespace,
			  let phoneNumberString = cnContact.phoneNumbers.first(
				where: { $0.value.stringValue.isWhitespace == false }
			  )?
			.value
			.stringValue else {
			return nil
		}
		let phoneNumberKit = PhoneNumberKit()
		guard let phoneNumber = try? phoneNumberKit.parse(phoneNumberString) else {
			return nil
		}
		guard phoneNumber.type == .mobile else {
			return nil
		}
		let formattedPhoneNumber = phoneNumberKit.format(
			phoneNumber,
			toType: .e164
		).withoutSpacesAndNewLines
		self.init(
			uid: formattedPhoneNumber,
			name: name,
			mobile: formattedPhoneNumber,
			photoURL: "",
			pushToken: "",
			publicKeyString: "",
			theme: .init(),
			lastMsgID: nil
		)
	}

	public var isChatAvailable: Bool { !pushToken.isWhitespace }

	public mutating func update(with user: Contact) {
		name = user.name
		if !user.photoURL.isWhitespace && user.photoURL != self.photoURL {
			photoURL = user.photoURL
		}
		if user.pushToken != self.pushToken {
			pushToken = user.pushToken
		}
		if user.publicKeyString != self.publicKeyString {
			publicKeyString = user.publicKeyString
		}
	}
}
extension PContact: SendableDocument {

	public typealias SendableType = Contact

	public convenience init(from sendable: Contact) {
		self.init(
			uid: sendable.id,
			name: sendable.name,
			mobile: sendable.mobile,
			photoURL: sendable.photoURL,
			pushToken: sendable.pushToken,
			publicKeyString: sendable.publicKeyString, theme: sendable.theme,
			lastMsgID: sendable.lastMsgID
		)
	}

	public func toSendable() -> Contact {
		.init(
			uid: uid,
			name: name,
			mobile: mobile,
			photoURL: photoURL,
			pushToken: pushToken,
			publicKeyString: publicKeyString, theme: theme,
			lastMsgID: lastMsgID
		)
	}
}
