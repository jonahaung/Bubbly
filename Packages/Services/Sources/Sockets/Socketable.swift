import Database
import FCM_V1
import FirebaseMessaging
import Foundation
import XUI

public protocol Socketable {
	func updateToLocal(_ msg: Message) async throws
	func notifyMessage(_ data: AnyMsgData) async
}

public extension Socketable {
	func updateToLocal(_ msg: Message) async throws {
		try await Store.shared.msgStore?
			.updateAndSaveDebounced(
				uid: msg.uid
			) { model in
				model.update(from: msg)
			}
	}

	@MainActor
	func notifyMessage(_ data: AnyMsgData) {
		NotificationCenter.default
			.post(name: .msgNoti(for: data.conID), object: data)
	}
}
