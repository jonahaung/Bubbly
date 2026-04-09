//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import FirebaseAuth
import FirebaseMessaging
import UIKit
import UserNotifications
import XUI

public final class PushNotificationService: NSObject, Sendable {
    override public init() {
        super.init()
    }

	@concurrent
    public func registerForPushNotifications() async throws {
        try await UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: [.alert, .badge, .sound]
            )
		await UIApplication.shared.registerForRemoteNotifications()
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

	@concurrent
    public func applicationDidBecomeActive() async throws {
        let datas = await PushNotificationStore.shared.consumePendingAnyMsgData()
        if !datas.isEmpty {
			let currentNavPath = await Router.shared.visiblePath()
            try await AsyncOrderedStream.mapOrdered(inputs: datas) { data in
                switch currentNavPath {
                case let .conversation(prefetchData):
                    if data.conID == prefetchData.configuration.conID {
                        await Socket.shared.receive(data)
                    }
                default:
                    await PushNotificationStore.shared.postInboxChanges()
                }
            }
        }
        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        try await UNUserNotificationCenter.current().setBadgeCount(0)
    }
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async
        -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        guard let data = try? AnyMsgData.parse(from: userInfo) else {
            return [.badge, .banner, .list, .sound]
        }
        let currentNavPath = await MainActor.run { Router.shared.visiblePath() }
        switch currentNavPath {
        case let .conversation(prefetchData):
            if data.conID == prefetchData.configuration.conID {
                await Socket.shared.receive(data)
                return []
            } else {
                return [.banner]
            }
        default:
            await PushNotificationStore.shared.postInboxChanges()
            return [.banner]
        }
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping ()
            -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
        guard let data = try? AnyMsgData.parse(from: userInfo) else {
            completionHandler()
            return
        }
        MainActor.assumeIsolated {
			if let url = data.deeplinkURL(coordinator: .init(router: Router.shared)) {
                UIApplication.shared.open(url)
            }
        }
        completionHandler()
    }
}

extension PushNotificationService: MessagingDelegate {
    public func messaging(
        _: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        Task { await PushNotificationStore.shared.handleRegistrationToken(fcmToken) }
    }
}
