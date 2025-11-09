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
    let pushNotificationService = PushNotificationService.shared
    let authService = AuthService()
    let router = Router.shared

    func application(
        _: UIApplication,
        didFinishLaunchingWithOptions _: [UIApplication.LaunchOptionsKey: Any]? = nil
    ) -> Bool {
        FirebaseApp.configure()
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        Auth.auth().shareAuthStateAcrossDevices = true
        try? Auth.auth().useUserAccessGroup(AppInformation.groupID)
        pushNotificationService.registerForPushNotifications { [weak self] in
            MainActor.assumeIsolated {
                debugPrint("1️⃣ Registered for push notifications")
                self?.authService.start()
            }
        }
        return true
    }

    func application(
        _: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error
    ) {
        debugPrint(error)
        fatalError()
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
