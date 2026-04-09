//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import Services
import SwiftUI
import XUI

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

	var pushNotificationServie: PushNotificationService?
	let backgroundTaskHandler: BackgroundTaskHandler = .init()

	func application(
		_: UIApplication,
		didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil,
	)
		-> Bool
	{
		FirebaseApp.configure()
		FirebaseKeychainSanitizer.sanitize()
		FirebaseConfiguration.shared.setLoggerLevel(.error)
		Auth.auth().shareAuthStateAcrossDevices = true
		pushNotificationServie = .init()
		return true
	}

	func application(
		_: UIApplication,
		didFailToRegisterForRemoteNotificationsWithError error: any Error,
	) {
		log(error)
	}

	func application(
		_: UIApplication,
		didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
	) {
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
		Messaging.messaging().apnsToken = deviceToken
	}

	func application(
		_: UIApplication,
		didReceiveRemoteNotification userInfo: [AnyHashable: Any],
	) async
		-> UIBackgroundFetchResult
	{
		if Auth.auth().canHandleNotification(userInfo) {
			return .noData
		}
		return .noData
	}
}

private extension AppDelegate {
	func registerForRemoteNotifications() {
		Task {
			do {
				try await pushNotificationServie?.registerForPushNotifications()
			} catch {
				log(error)
			}
		}
	}
}
