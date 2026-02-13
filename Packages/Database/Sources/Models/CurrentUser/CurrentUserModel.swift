import Core
import FirebaseAuth
import FirebaseMessaging
import Foundation
import XUI

public struct CurrentUserModel: ContactRepresentableSendable, Codable, Hashable, Equatable {
	public let uid: String
	public var name: String
	public let mobile: String
	public var photoURL: String
	public var pushToken: String
	public var publicKeyString: String

	public init(uid: String,
	            name: String,
	            mobile: String,
	            photoURL: String,
	            pushToken: String,
	            publicKeyString: String)
	{
		self.uid = uid
		self.name = name
		self.mobile = mobile
		self.photoURL = photoURL
		self.pushToken = pushToken
		self.publicKeyString = publicKeyString
	}
}

public extension CurrentUserModel {
	init(_ user: FirebaseAuth.User) {
		self.init(
			uid: user.uid,
			name: user.displayName.str,
			mobile: user.phoneNumber.str,
			photoURL: user.photoURL?.absoluteString ?? "",
			pushToken: Messaging.messaging().fcmToken ?? "",
			publicKeyString: CryptoService.shared.base64PublicKeyString(for: user.uid)
		)
	}

	static let empty: CurrentUserModel = .init(
		uid: "",
		name: "",
		mobile: "",
		photoURL: "",
		pushToken: "",
		publicKeyString: ""
	)
}
