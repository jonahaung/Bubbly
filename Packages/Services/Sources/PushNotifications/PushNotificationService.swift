//
//  PushNotificationService.swift
//  Services
//
//  Created by Aung Ko Min on 2/5/25.
//

import UIKit
import UserNotifications
import XUI
import FirebaseMessaging
import Database
import Core

public final class PushNotificationService: NSObject, Sendable {

	public override init() {
		super.init()
	}

	public func register() {
		UNUserNotificationCenter
			.current()
			.requestAuthorization(
				options: [
					.alert,
					.badge,
					.sound,
					.provisional,
					.criticalAlert,
					.providesAppNotificationSettings
				]
			) {
				[weak self] _,
				error in
				guard let self else { return }
				DispatchQueue.main.async {
					if let error {
						Log(error)
					} else {
						UIApplication.shared.registerForRemoteNotifications()
						UNUserNotificationCenter.current().delegate = self
						Messaging.messaging().delegate = self
					}
				}
			}
	}
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
	public func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		willPresent notification: UNNotification
	) async -> UNNotificationPresentationOptions {
		let userInfo = notification.request.content.userInfo
		guard let data = AnyMsgData(userInfo: userInfo) else {
			return [.badge, .banner, .list, .sound]
		}
		guard let currentNavPath = await Router.shared.currentNavRouter?.navPath.last else {
			NotificationCenter.default
				.post(name: .inboxChanges, object: nil)
			return [.badge, .banner, .list, .sound]
		}
		switch currentNavPath {
		case .conversation(let conversationKit):
			if data.conID == conversationKit.conversation.uid {
				await Socket.shared.receive(data)
				return []
			} else {
				return [.banner]
			}
		default:
			NotificationCenter.default
				.post(name: .inboxChanges, object: nil)
			return [.banner, .sound]
		}
	}
	public func userNotificationCenter(
		_ center: UNUserNotificationCenter,
		didReceive response: UNNotificationResponse,
		withCompletionHandler completionHandler: @escaping () -> Void
	) {
		let userInfo = response.notification.request.content.userInfo
		NotificationCenter.default
			.post(
				name: .tapPushNotificationAction,
				object: nil,
				userInfo: userInfo
			)
		completionHandler()
	}
}
extension PushNotificationService: MessagingDelegate {
	public func messaging(
		_ messaging: Messaging,
		didReceiveRegistrationToken fcmToken: String?
	) {
		GroupAppStorage.shared.save(value: fcmToken, for: .device(.deviceToken))
		NotificationCenter.default
			.post(name: .receiveDeviceToken, object: fcmToken)
	}
}
