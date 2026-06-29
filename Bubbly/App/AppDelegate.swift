//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Services
import UIKit

@MainActor
final class AppDelegate: NSObject, UIApplicationDelegate {

    let runtime = AppRuntime()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions options: [UIApplication.LaunchOptionsKey: Any]? = nil,
    ) -> Bool {
        runtime.configureApplication()
        return true
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        runtime.didBecomeActive()
    }

    func applicationWillResignActive(_ application: UIApplication) {
        runtime.willResignActive()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        runtime.didEnterBackground()
    }

    func application(
        _ application: UIApplication,
        didFailToRegisterForRemoteNotificationsWithError error: any Error,
    ) {
        runtime.didFailToRegisterForRemoteNotifications(error: error)
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data,
    ) {
        runtime.didRegisterForRemoteNotifications(deviceToken: deviceToken)
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
    ) async -> UIBackgroundFetchResult {
        return runtime.didReceiveRemoteNotification(userInfo)
    }
}
