import Core
import Database
import FirebaseAuth
import FirebaseCore
import FirebaseMessaging
import Services
import UIKit
import XUI

@MainActor
final class AppRuntime {

    private let backgroundTaskHandler = BackgroundTaskHandler()
    private let deeplinkCoordinator = DeepLinkCoordinator()
    private let pushNotificationService = PushNotificationService()
    private var hasRegisteredForPushNotifications = false
    let router: Router = .shared
    let appLauncher = AppLauncher()

    func configureApplication() {
        FirebaseApp.configure()
        FirebaseKeychainSanitizer.sanitize()
        FirebaseConfiguration.shared.setLoggerLevel(.error)
        Auth.auth().shareAuthStateAcrossDevices = true
        pushNotificationService.configureDelegates()
    }

    func captureLaunchNotification(_ userInfo: [AnyHashable: Any]) {
        pushNotificationService.captureLaunchNotification(userInfo)
    }

    func openURL(_ url: URL) {
        if Auth.auth().canHandle(url) {
            
        } else {
            Task {
                await deeplinkCoordinator.onOpenURL(url: url, router: router)
            }
        }
    }

    func didBecomeActive() {
        AppStateStore.set(.active)
        Task {
            await handleDidBecomeActive()
        }
    }

    func willResignActive() {
        AppStateStore.set(.inactive)
    }

    func didEnterBackground() {
        AppStateStore.set(.background)
        backgroundTaskHandler.scheduleAppRefresh()
    }

    func didFailToRegisterForRemoteNotifications(error: any Error) {
        log(error)
    }

    func didRegisterForRemoteNotifications(deviceToken: Data) {
        #if DEBUG
        Auth.auth().setAPNSToken(deviceToken, type: .sandbox)
        #else
        Auth.auth().setAPNSToken(deviceToken, type: .prod)
        #endif
        Messaging.messaging().apnsToken = deviceToken
    }

    func didReceiveRemoteNotification(_ userInfo: [AnyHashable: Any])
        -> UIBackgroundFetchResult
    {
        if Auth.auth().canHandleNotification(userInfo) {
            return .noData
        }
        return .noData
    }

    func handleAppRefresh() async {
        await backgroundTaskHandler.handleAppRefresh()
    }

    func startAppLauncher() async {
        await appLauncher.startEvaluate(router: router)
    }

    private func handleDidBecomeActive() async {
        do {
            try await pushNotificationService.applicationDidBecomeActive()
            await PendingDeeplinkStore.shared.drainIfReady()
        } catch {
            log(error)
        }
    }

    func registerForPushNotificationsIfNeeded() async throws {
        guard !hasRegisteredForPushNotifications else {
            return
        }
        hasRegisteredForPushNotifications = true
        do {
            try await pushNotificationService.registerForPushNotifications()
        } catch {
            hasRegisteredForPushNotifications = false
            throw error
        }
    }
}
