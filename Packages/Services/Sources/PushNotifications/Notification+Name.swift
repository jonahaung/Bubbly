//
//  Notification+Name.swift
//  Services
//
//  Created by Aung Ko Min on 2/3/25.
//

import Combine
import Database
import Foundation

public extension Notification.Name {
	static func msgNoti(for conID: String) -> Notification.Name {
		Notification.Name("conversation=\(conID)")
	}

	static let receiveDeviceToken = Notification.Name("receiveDeviceToken")
	static let inboxChanges = Notification.Name("inboxChanges")
}

public extension NotificationCenter.Publisher.Output {
	var anyMsgData: AnyMsgData? {
		object as? AnyMsgData
	}
}
