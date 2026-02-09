//
//  AppDelegate.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
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
	func application(_: UIApplication,
	                 didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil)
		-> Bool
	{
		FirebaseApp.configure()
		FirebaseKeychainSanitizer.sanitize()
		FirebaseConfiguration.shared.setLoggerLevel(.error)
		Auth.auth().shareAuthStateAcrossDevices = true
		return true
	}

	func application(_: UIApplication,
	                 didFailToRegisterForRemoteNotificationsWithError error: any Error)
	{
		debugPrint(error)
	}

	func application(_: UIApplication,
	                 didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data)
	{
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
		Messaging.messaging().apnsToken = deviceToken
	}

	func application(_: UIApplication,
	                 didReceiveRemoteNotification userInfo: [AnyHashable: Any]) async
		-> UIBackgroundFetchResult
	{
		.noData
//		guard let data = AnyMsgData(userInfo: userInfo) else {
//			return .noData
//		}
//		print(data)
//		await Socket.shared.receive(data)
//		NotificationCenter.default
//			.post(name: .inboxChanges, object: nil)
//		return .newData
		// If you intend to reach this code, restructure the returns above.
		// Keeping it for reference:
		// if Auth.auth().canHandleNotification(userInfo) {
		//     return .newData
		// } else {
		//     Messaging.messaging().appDidReceiveMessage(userInfo)
		//     return .newData
		// }
	}
}
