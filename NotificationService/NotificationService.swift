import Core
import Crypto
import Database
import Firebase
import os
import Services
import UserNotifications
import XUI

/**
 Guarded Firebase init:
 if FirebaseApp.app() == nil { FirebaseApp.configure() }
 Ensured content handler is always called when mutableCopy() fails.
 Replaced [unowned bestAttemptContent] with safe [weak self] fallback to bestAttemptContent → originalContent → request.content.
 Stored the async Task in processingTask and cancel it in serviceExtensionTimeWillExpire()
 */
final class NotificationService: UNNotificationServiceExtension {
	private var contentHandler: ((UNNotificationContent) -> Void)?
	private var bestAttemptContent: UNMutableNotificationContent?
	private var originalContent: UNNotificationContent?
	private var processingTask: Task<Void, Never>?
	private let logger = Logger(
		subsystem: "com.bubbly.app",
		category: "NotificationServiceExtension"
	)

	override init() {
		super.init()
		if FirebaseApp.app() == nil {
			FirebaseApp.configure()
		}
	}

	override func didReceive(_ request: UNNotificationRequest,
	                         withContentHandler contentHandler: @escaping (UNNotificationContent)
	                         	-> Void)
	{
		if let id = GroupStorage.shared.string(for: .auth(.currentUserID)) {
			Task {
				if await !Store.shared.hasSetUp(for: id) {
					await Store.shared
						.start(with: id)
				}
			}
		}

		self.contentHandler = contentHandler
		originalContent = request.content
		bestAttemptContent = (request.content.mutableCopy() as? UNMutableNotificationContent)

		guard let bestAttemptContent else {
			logger
				.warning(
					"Failed to create mutable notification content; falling back to original content."
				)
			contentHandler(request.content)
			return
		}

		guard let data = try? AnyMsgData.parse(from: bestAttemptContent.userInfo) else {
			contentHandler(bestAttemptContent)
			return
		}
		bestAttemptContent.subtitle = data.pushNotificationSubtitle
		bestAttemptContent.body = data.pushNotificationBody
		logger.info("Last known app state: \(AppStateStore.read().rawValue, privacy: .public)")

		processNotificationData(data) { [weak self] _ in
			if let bestAttemptContent = self?.bestAttemptContent {
				contentHandler(bestAttemptContent)
			} else {
				if let originalContent = self?.originalContent {
					self?.logger
						.info("bestAttemptContent missing; using original content fallback.")
					contentHandler(originalContent)
				} else {
					self?.logger
						.error(
							"Both bestAttemptContent and originalContent missing; using request content fallback."
						)
					contentHandler(request.content)
				}
			}
		}
	}

	override func serviceExtensionTimeWillExpire() {
		processingTask?.cancel()
		if let contentHandler, let bestAttemptContent {
			contentHandler(bestAttemptContent)
		} else if let contentHandler, let originalContent {
			contentHandler(originalContent)
		}
	}

	// MARK: - Private Methods

	private func processNotificationData(_ data: AnyMsgData,
	                                     sending completion: @escaping (Bool) -> Void)
	{
		processingTask = Task {
			do {
				try await Socket.shared.handleReceive(data)
				completion(true)
			} catch {
				completion(false)
			}
		}
	}
}
