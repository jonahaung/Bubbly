//
//  Socketable.swift
//  Services
//
//  Created by Aung Ko Min on 2/3/25.
//
//
//  Socketable.swift
//  Services
//
//  Created by Aung Ko Min on 2/3/25.
//

import Foundation
import XUI
import Database
import FirebaseMessaging
import FCM_V1

public protocol Socketable {
	func updateToLocal(_ msg: Message) async throws
	func notifyMessage(_ data: AnyMsgData) async
}
public extension Socketable {
	func updateToLocal(_ msg: Message) async throws {
		try await Store.shared.msgStore.updateAndSaveDebounced(uid: msg.uid) { model in
			model.update(with: msg)
		}
	}
	@MainActor
	func notifyMessage(_ data: AnyMsgData) {
		NotificationCenter.default
			.post(name: .msgNoti(for: data.conID), object: data)
	}
}
