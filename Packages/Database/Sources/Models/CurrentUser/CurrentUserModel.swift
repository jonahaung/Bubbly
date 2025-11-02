//
//  CurrentUserModel.swift
//  Services
//
//  Created by Aung Ko Min on 29/10/25.
//

import Foundation
import FirebaseAuth
import XUI
import Core
import FirebaseMessaging

public struct CurrentUserModel: ContactRepresentable {
	public let uid: String
	public var name: String
	public let mobile: String
	public var photoURL: String
	public var pushToken: String
	public var publicKeyString: String

	public init(
		uid: String,
		name: String,
		mobile: String,
		photoURL: String,
		pushToken: String,
		publicKeyString: String
	) {
		self.uid = uid
		self.name = name
		self.mobile = mobile
		self.photoURL = photoURL
		self.pushToken = pushToken
		self.publicKeyString = publicKeyString
	}

	// MARK: - Equatable (Value-based)
	public static func == (lhs: CurrentUserModel, rhs: CurrentUserModel) -> Bool {
		return lhs.uid == rhs.uid &&
		lhs.name == rhs.name &&
		lhs.mobile == rhs.mobile &&
		lhs.photoURL == rhs.photoURL &&
		lhs.pushToken == rhs.pushToken &&
		lhs.publicKeyString == rhs.publicKeyString
	}

	// MARK: - Hashable (Value-based)
	public func hash(into hasher: inout Hasher) {
		hasher.combine(uid)
		hasher.combine(name)
		hasher.combine(mobile)
		hasher.combine(photoURL)
		hasher.combine(pushToken)
		hasher.combine(publicKeyString)
	}
}
public extension CurrentUserModel {
	init(_ user: User) {
		self.init(
			uid: user.uid,
			name: user.displayName.str,
			mobile: user.phoneNumber.str,
			photoURL: user.photoURL?.absoluteString ?? "",
			pushToken: Messaging.messaging().fcmToken ?? "",
			publicKeyString: CryptoService.shared.publicKeyString
		)
	}
	static let empty: CurrentUserModel = .init(uid: "", name: "", mobile: "", photoURL: "", pushToken: "", publicKeyString: "")
}
