//
//  Notification+Name.swift
//  Services
//
//  Created by Aung Ko Min on 2/3/25.
//

import Foundation
import Combine
import Database

public extension Notification.Name {
	static func msgNoti(for conID: String) -> Notification.Name {
		Notification.Name("conversation=\(conID)")
	}
	static let tapPushNotificationAction = Notification.Name("tapPushNotificationAction")
	static let receiveDeviceToken = Notification.Name("receiveDeviceToken")
	static let inboxChanges = Notification.Name("inboxChanges")
}

public extension NotificationCenter.Publisher.Output {
	var anyMsgData: AnyMsgData? {
		self.object as? AnyMsgData
	}
}
