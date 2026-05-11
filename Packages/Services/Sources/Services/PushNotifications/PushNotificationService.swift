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
    override public init() {
        super.init()
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
        Messaging.messaging().delegate = self
        UNUserNotificationCenter.current().delegate = self
    }

    @concurrent
    public func applicationDidBecomeActive() async throws {
        let datas = await PushNotificationStore.shared
            .consumePendingAnyMsgData()
        if !datas.isEmpty {
            let currentNavPath = await Router.shared.visiblePath()
            var shouldRefreshInbox = false
            var nextPendingIndex: Int? = nil

            do {
                for (index, data) in datas.enumerated() {
                    nextPendingIndex = index
                    let didAffectInbox = try await process(
                        data,
                        for: currentNavPath,
                    )
                    shouldRefreshInbox = shouldRefreshInbox || didAffectInbox
                }
                if shouldRefreshInbox {
                    await PushNotificationStore.shared.postInboxChanges()
                }
            } catch {
                let pending =
                    nextPendingIndex.map { Array(datas[$0...]) } ?? datas
                await PushNotificationStore.shared.savePendingAnyMsgData(
                    pending
                )
                throw error
            }
        }
//        UNUserNotificationCenter.current().removeAllDeliveredNotifications()
//        try await UNUserNotificationCenter.current().setBadgeCount(0)
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

        let currentNavPath = await MainActor.run { Router.shared.visiblePath() }
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
        let userInfo = response.notification.request.content.userInfo
        let data: AnyMsgData
        do {
            data = try AnyMsgData.parse(from: userInfo)
        } catch {
            log(error)
            completionHandler()
            return
        }

        Task { @MainActor in
            if let url = data.deeplinkURL(
                coordinator: .init(router: Router.shared)
            ) {
                UIApplication.shared.open(url)
            }
        }
        completionHandler()
    }
}

extension PushNotificationService {
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
