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

    private var contentHandler: ((UNNotificationContent) -> Void)?
    private var bestAttemptContent: UNMutableNotificationContent?

    override init() {
        super.init()
        FirebaseApp.configure()
    }

    override func didReceive(
        _ request: UNNotificationRequest,
        withContentHandler contentHandler: @escaping (UNNotificationContent) -> Void
    ) {
        self.contentHandler = contentHandler
        bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

        guard let bestAttemptContent else {
            return
        }
		
		guard let data = try? AnyMsgData.parse(from: bestAttemptContent.userInfo) else {
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
		if let contentHandler = contentHandler, let bestAttemptContent = bestAttemptContent {
			contentHandler(bestAttemptContent)
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
