//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
class AppDelegate: NSObject, UIApplicationDelegate {
	func application(
		_: UIApplication,
		didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
	)
		-> Bool
	{
		FirebaseApp.configure()
		FirebaseKeychainSanitizer.sanitize()
		FirebaseConfiguration.shared.setLoggerLevel(.error)
		Auth.auth().shareAuthStateAcrossDevices = true
		return true
	}

	func application(
		_: UIApplication,
		didFailToRegisterForRemoteNotificationsWithError error: any Error
	) {
		debugPrint(error)
	}

	func application(
		_: UIApplication,
		didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
	) {
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
		Messaging.messaging().apnsToken = deviceToken
	}

	func application(
		_: UIApplication,
		didReceiveRemoteNotification _: [AnyHashable: Any]
	) async
		-> UIBackgroundFetchResult
	{
		.noData
	}
}
