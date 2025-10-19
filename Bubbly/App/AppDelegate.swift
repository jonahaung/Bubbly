//
//  AppDelegate.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import SwiftUI
import Services
import FirebaseCore
import FirebaseAuth
import FirebaseMessaging
import Database
import Core

@MainActor
class AppDelegate: NSObject, UIApplicationDelegate {

	let pushNotificationService = PushNotificationService()
	lazy var authService = AuthService()

	func application(
		_ application: UIApplication,
		didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
	) -> Bool {
		FirebaseApp.configure()
		pushNotificationService.register()
		return true
	}

	func application(
		_ application: UIApplication,
		didFailToRegisterForRemoteNotificationsWithError error: any Error
	) {
		debugPrint(error)
		fatalError()
	}

	func application(
		_ application: UIApplication,
		didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
	) {
		Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
		Messaging.messaging().apnsToken = deviceToken
	}

	func application(
		_ application: UIApplication,
		didReceiveRemoteNotification userInfo: [AnyHashable: Any]
	) async -> UIBackgroundFetchResult {
		if Auth.auth().canHandleNotification(userInfo) {
			return .noData
		} else {
			Messaging.messaging().appDidReceiveMessage(userInfo)
			return .newData
		}
	}
}
