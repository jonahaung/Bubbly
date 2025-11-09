//
//  Notification+Name.swift
//  Services
//
//  Created by Aung Ko Min on 2/3/25.
//

import Combine
import Database
import Foundation

extension Notification.Name {
	public static func msgNoti(for conID: String) -> Notification.Name {
		Notification.Name("conversation=\(conID)")
	}

	public static let tapPushNotificationAction = Notification.Name("tapPushNotificationAction")
	public static let receiveDeviceToken = Notification.Name("receiveDeviceToken")
	public static let inboxChanges = Notification.Name("inboxChanges")
}

extension NotificationCenter.Publisher.Output {
	public var anyMsgData: AnyMsgData? {
		object as? AnyMsgData
	}
}
