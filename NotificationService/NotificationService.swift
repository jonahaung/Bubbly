//
//  NotificationService.swift
//  NotificationService
//
//  Created by Aung Ko Min on 27/4/25.
//

import Core
import Crypto
import Database
import Firebase
import Services
import UserNotifications
import XUI

final class NotificationService: UNNotificationServiceExtension {
    // MARK: - Properties

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    // MARK: - Initialization

    override init() {
        super.init()
        FirebaseApp.configure()
    }

    // MARK: - Notification Handling

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            contentHandler(request.content)
            return
        }

        guard let data = AnyMsgData(userInfo: bestAttemptContent.userInfo) else {
            contentHandler(bestAttemptContent)
            return
        }
        bestAttemptContent.subtitle = data.pushNotificationSubtitle
        bestAttemptContent.body = data.pushNotificationBody

        processNotificationData(data) { [weak bestAttemptContent] _ in
            guard let bestAttemptContent else { return }
            contentHandler(bestAttemptContent)
        }
    }

    override func serviceExtensionTimeWillExpire() {
        if let content = bestAttemptContent, let data = AnyMsgData(
            userInfo: content
                .userInfo) {
            processNotificationData(data) { [weak self] _ in
                guard let self else { return }
                contentHandler?(content)
            }
        }
    }

    // MARK: - Private Methods

    private func processNotificationData(
        _ data: AnyMsgData,
        sending completion: @escaping (Bool) -> Void
    ) {
        Task {
            do {
                try await Socket.shared.handleReceive(data)
                completion(true)
            } catch {
                completion(false)
            }
        }
    }
}
