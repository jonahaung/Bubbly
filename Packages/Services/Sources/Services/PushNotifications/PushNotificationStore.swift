// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import Foundation
import XUI

public actor PushNotificationStore {
    @SocketActor
    struct NotificationCenterProxy: Sendable {
        let center: NotificationCenter
    }

    struct Dependencies: @unchecked Sendable {
        let storage: GroupStorage
        let notificationCenter: NotificationCenterProxy
        let authProvider: @Sendable () -> User?
        let updatePushToken: @Sendable (_ token: String, _ userID: String) async throws -> Void

        static var live: Dependencies {
            Dependencies(
                storage: .shared,
                notificationCenter: .init(center: .default),
                authProvider: { Auth.auth().currentUser },
                updatePushToken: { token, userID in
                    try await FirestoreRepo.update(
                        value: ["pushToken": token],
                        collectionPath: .users,
                        to: userID,
                    )
                },
            )
        }
    }

    public static let shared: PushNotificationStore = .init()
    private let deps: Dependencies

    init(dependencies: Dependencies = .live) {
        deps = dependencies
    }

    public func consumePendingAnyMsgData(navPath: NavPath?) async throws {
        guard let datas = deps.storage.codable([AnyMsgData].self, for: .device(.anyMsgData)) else {
            return
        }
        deps.storage.delete(for: .device(.anyMsgData))
        switch navPath {
        case .conversation(let prefetchData):
            let center = deps.notificationCenter
            try await AsyncOrderedStream.mapOrdered(inputs: datas) { data in
                if data.conID == prefetchData.conversation.uid {
                    center.center.post(name: .msgNoti(for: data.conID), object: data)
                }
            }
        default:
            await postInboxChanges()
        }
    }

    public func savePendingAnyMsgData(_ datas: [AnyMsgData]) {
        guard !datas.isEmpty else {
            deps.storage.delete(for: .device(.anyMsgData))
            return
        }
        deps.storage.save(datas, for: .device(.anyMsgData))
    }

    public func postReceiveDeviceToken(_ fcmToken: String?) async {
        let center = deps.notificationCenter
        await MainActor.run {
            center.center.post(name: .receiveDeviceToken, object: fcmToken)
        }
    }

    public func postInboxChanges() async {
        let center = deps.notificationCenter
        await MainActor.run {
            center.center.post(name: .inboxChanges, object: nil)
        }
    }
    public func postReceiveNewMessages(data: [AnyMsgData]) async {
        let center = deps.notificationCenter
        await MainActor.run {
            center.center.post(name: .inboxChanges, object: nil)
        }
    }

    public func handleRegistrationToken(_ fcmToken: String?) async {
        await postReceiveDeviceToken(fcmToken)
        await uploadTokenIfNeeded(fcmToken)
    }

    public func uploadTokenIfNeeded(_ fcmToken: String?) async {
        let storedToken = deps.storage.string(for: .device(.deviceToken))
        guard
            let fcmToken,
            !fcmToken.isEmpty,
            storedToken != fcmToken,
            let user = deps.authProvider() else
        {
            return
        }

        do {
            deps.storage.save(fcmToken, for: .device(.deviceToken))
            try await deps.updatePushToken(fcmToken, user.uid)
            log(
                "Updated fcmToken (\(fcmToken)) to Firestore for user: \(user.displayName ?? user.uid)",
            )
        } catch {
            log(error)
        }
    }
}
