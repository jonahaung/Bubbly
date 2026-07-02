// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import UIKit
import UserNotifications
import XUI

// MARK: - PushNotificationService

public final class PushNotificationService: NSObject, Sendable {
    private let routeParser: PushNotificationRouteParser

    public override init() {
        routeParser = .init()
    }

    @concurrent
    public func registerForPushNotifications() async throws {
        try await UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: [
                    .alert, .badge, .sound,
                ]
            )
        await UIApplication.shared.registerForRemoteNotifications()
        configureDelegates()
    }

    public func configureDelegates() {
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    public func captureLaunchNotification(_ userInfo: [AnyHashable: Any]) {
        do {
            let route = try routeParser.parse(userInfo: userInfo)
            Task {
                await enqueuePendingRoute(route)
            }
        } catch {
            log(error)
        }
    }

    @concurrent
    public func applicationDidBecomeActive() async throws {
        let currentNavPath = await Router.shared.visiblePath()
        try await PushNotificationStore.shared.consumePendingAnyMsgData(
            navPath: currentNavPath
        )
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        try await UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

// MARK: UNUserNotificationCenterDelegate

extension PushNotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification,
    ) async
        -> UNNotificationPresentationOptions
    {
        let userInfo = notification.request.content.userInfo
        let data: AnyMsgData
        do {
            data = try AnyMsgData.parse(from: userInfo)
        } catch {
            log(error)
            return [.badge, .banner, .list, .sound]
        }

        let currentNavPath = await Router.shared.visiblePath()
        do {
            switch currentNavPath {
            case .conversation(let prefetchData)
            where data.conID == prefetchData.conversation.uid:
                try await Socket.shared.notifyMessage(data)
                return []
            default:
                let didAffectInbox = try await process(
                    data,
                    for: currentNavPath
                )
                if didAffectInbox {
                    await PushNotificationStore.shared.postInboxChanges()
                }
                return [.banner]
            }
        } catch {
            log(error)
            return [.badge, .banner, .list, .sound]
        }
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler:
            @escaping ()
            -> Void,
    ) {
        do {
            let route = try routeParser.parse(
                userInfo: response.notification.request.content.userInfo
            )
            Task {
                await enqueuePendingRoute(route)
            }
        } catch {
            log(error)
        }
        completionHandler()
    }
}

extension PushNotificationService {
    private func enqueuePendingRoute(_ route: Deeplink) async {
        await PendingDeeplinkStore.shared.enqueue(route)
        await PendingDeeplinkStore.shared.drainIfReady()
    }

    fileprivate func process(
        _ data: AnyMsgData,
        for currentNavPath: NavPath?
    ) async throws -> Bool {
        switch currentNavPath {
        case .conversation(let prefetchData)
        where data.conID == prefetchData.conversation.uid:
            //            try await Socket.shared.receive(data)
            return false
        default:
            //            try await Socket.shared.receive(data)
            return true
        }
    }
}

// MARK: MessagingDelegate

extension PushNotificationService: MessagingDelegate {
    public func messaging(
        _: Messaging,
        didReceiveRegistrationToken fcmToken: String?,
    ) {
        Task {
            await PushNotificationStore.shared.handleRegistrationToken(fcmToken)
        }
    }
}
