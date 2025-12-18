//
//  PushNotificationService.swift
//  Services
//
//  Created by Aung Ko Min on 2/5/25.
//

import Core

// import FirebaseFirestore
import Database
import FirebaseAuth
import FirebaseMessaging
import UIKit
import UserNotifications
import XUI

public final class PushNotificationService: NSObject, Sendable {
    public static let shared = PushNotificationService()

    override private init() {
        super.init()
    }

    public func registerForPushNotifications(
        completion: @escaping @Sendable @MainActor () -> Void
    ) {
        UNUserNotificationCenter
            .current()
            .requestAuthorization(
                options: [
                    .alert,
                    .badge,
                    .sound
                ]
            ) {
                success,
                    error in
                if let error {
                    Log(error)
                } else if success {
                    Task { @MainActor in
                        UIApplication.shared.registerForRemoteNotifications()
                        Messaging.messaging().delegate = self
                        UNUserNotificationCenter.current().delegate = self
                        completion()
                    }
                    return
                }
                Task { @MainActor in
                    completion()
                }
            }
    }

	public func removeAllNotifications() {
		UNUserNotificationCenter.current().removeAllDeliveredNotifications()
		UNUserNotificationCenter.current().setBadgeCount(0)
	}
}

extension PushNotificationService: UNUserNotificationCenterDelegate {
    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        willPresent notification: UNNotification
    ) async -> UNNotificationPresentationOptions {
        let userInfo = notification.request.content.userInfo
        guard let data = AnyMsgData(userInfo: userInfo) else {
            return [.badge, .banner, .list, .sound]
        }
		guard let currentNavPath = await Router.shared.currentNavPath else {
            NotificationCenter.default
                .post(name: .inboxChanges, object: nil)
            return [.badge, .banner, .list, .sound]
        }
        switch currentNavPath {
        case let .conversation(conversationKit):
            if data.conID == conversationKit.configuration.conID {
                await Socket.shared.receive(data)
				return []
            } else {
                return [.banner]
            }
        default:
            NotificationCenter.default
                .post(name: .inboxChanges, object: nil)
            return [.banner, .sound]
        }
    }

    public func userNotificationCenter(
        _: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        let userInfo = response.notification.request.content.userInfo
		guard let data = AnyMsgData(userInfo: userInfo) else {
			return
		}
		ConversationInitializer.start(conID: data.conID, refetch: false, delay: 0)
        completionHandler()
    }
}

extension PushNotificationService: MessagingDelegate {
    public func messaging(
        _: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        PushNotificationService.shared.uploadTokenToFirestore(fcmToken)
    }
}

public extension PushNotificationService {
    func uploadTokenToFirestore(_ fcmToken: String?) {
        GroupStorage.shared.save(fcmToken, for: .device(.deviceToken))
        NotificationCenter.default
            .post(name: .receiveDeviceToken, object: fcmToken)
        //		guard
        //			let fcmToken,
        //			!fcmToken.isEmpty,
        //			let user = Auth.auth().currentUser
        //		else {
        //			debugPrint("⚠️ Skipping Firestore upload — no token or user.")
        //			return
        //		}
        //		do {
        //			try await FirestoreRepo.update(value: [Contact.CodingKeys.pushToken.rawValue: fcmToken], collectionPath: .users, to: user.uid)
        //			Log("Updated fcmToken (\(fcmToken) to Firestore for user: \(user.displayName ?? user.uid)")
        //		} catch {
        //			Log(error)
        //		}
    }
}
