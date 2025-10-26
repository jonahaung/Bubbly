import Foundation
@preconcurrency import UserNotifications

// MARK: - Domain Types

public struct NotificationContent: @unchecked Sendable {
	public let id: String
	public let title: String
	public let subtitle: String
	public let body: String
	public let badge: NSNumber?
	public let sound: UNNotificationSound?
	public let launchImageName: String?
	public let userInfo: [AnyHashable: Any]
	public let categoryIdentifier: String?
	public let threadIdentifier: String?
	public let targetContentIdentifier: String?
	public let interruptionLevel: UNNotificationInterruptionLevel?
	public let relevanceScore: Double?

	public init(
		id: String = UUID().uuidString,
		title: String,
		subtitle: String = "",
		body: String = "",
		badge: NSNumber? = nil,
		sound: UNNotificationSound? = .default,
		launchImageName: String? = nil,
		userInfo: [AnyHashable: Any] = [:],
		categoryIdentifier: String? = nil,
		threadIdentifier: String? = nil,
		targetContentIdentifier: String? = nil,
		interruptionLevel: UNNotificationInterruptionLevel? = nil,
		relevanceScore: Double? = nil
	) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.body = body
		self.badge = badge
		self.sound = sound
		self.launchImageName = launchImageName
		self.userInfo = userInfo
		self.categoryIdentifier = categoryIdentifier
		self.threadIdentifier = threadIdentifier
		self.targetContentIdentifier = targetContentIdentifier
		self.interruptionLevel = interruptionLevel
		self.relevanceScore = relevanceScore
	}
}

public struct NotificationRequest: Sendable {
	public let content: NotificationContent
	public let trigger: UNNotificationTrigger?
	public let authorizationOptions: UNAuthorizationOptions

	public init(
		content: NotificationContent,
		trigger: UNNotificationTrigger? = nil,
		authorizationOptions: UNAuthorizationOptions = [.alert, .badge, .sound]
	) {
		self.content = content
		self.trigger = trigger
		self.authorizationOptions = authorizationOptions
	}
}

// MARK: - Abstractions

public protocol NotificationScheduler: Sendable {
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
	func add(_ request: UNNotificationRequest) async throws

}

extension UNUserNotificationCenter: NotificationScheduler {

	public func add(_ request: UNNotificationRequest) async throws {
		try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
			self.add(request) { error in
				if let error {
					continuation.resume(throwing: error)
				} else {
					continuation.resume()
				}
			}
		}
	}
}

// MARK: - Service Protocol

public protocol NotificationService: Sendable {
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
	func schedule(request: NotificationRequest) async
	func sendAlert(title: String, subtitle: String, body: String) async
}

// MARK: - Local Notification Service

public actor DefaultNotificationService: NotificationService {

	// MARK: - Properties

	private let scheduler: NotificationScheduler
	private let settingsProvider: NotificationSettingsProvider

	// MARK: - Initialization

	public init(
		scheduler: NotificationScheduler = UNUserNotificationCenter.current(),
		settingsProvider: NotificationSettingsProvider = DefaultNotificationSettingsProvider()
	) {
		self.scheduler = scheduler
		self.settingsProvider = settingsProvider
	}

	// MARK: - Public API

	public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		try await scheduler.requestAuthorization(options: options)
	}

	public func schedule(request: NotificationRequest) async {
		do {
			// Check authorization status first
			let settings = await settingsProvider.getSettings()

			guard settings.authorizationStatus == .authorized else {
				print("Notification authorization not granted. Current status: \(settings.authorizationStatus.rawValue)")
				return
			}

			// Verify required permissions are enabled
			if request.authorizationOptions.contains(.alert) && settings.alertSetting != .enabled {
				print("Alert notifications are not enabled")
				return
			}

			if request.authorizationOptions.contains(.badge) && settings.badgeSetting != .enabled {
				print("Badge notifications are not enabled")
				return
			}

			if request.authorizationOptions.contains(.sound) && settings.soundSetting != .enabled {
				print("Sound notifications are not enabled")
				return
			}

			let content = makeContent(from: request.content)
			let notificationRequest = UNNotificationRequest(
				identifier: request.content.id,
				content: content,
				trigger: request.trigger
			)

			try await scheduler.add(notificationRequest)
		} catch {
			print("Failed to schedule notification: \(error.localizedDescription)")
		}
	}

	public func sendAlert(title: String, subtitle: String = "", body: String = "") async {
		let content = NotificationContent(
			title: title,
			subtitle: subtitle,
			body: body,
			sound: nil
		)

		let request = NotificationRequest(
			content: content,
			authorizationOptions: [.alert]
		)

		await schedule(request: request)
	}

	// MARK: - Private Helpers

	private func makeContent(from content: NotificationContent) -> UNMutableNotificationContent {
		let notificationContent = UNMutableNotificationContent()
		notificationContent.title = content.title
		notificationContent.subtitle = content.subtitle
		notificationContent.body = content.body
		notificationContent.badge = content.badge
		notificationContent.sound = content.sound
		notificationContent.launchImageName = content.launchImageName ?? "default"
		notificationContent.userInfo = content.userInfo
		notificationContent.categoryIdentifier = content.categoryIdentifier ?? ""
		notificationContent.threadIdentifier = content.threadIdentifier ?? ""
		notificationContent.targetContentIdentifier = content.targetContentIdentifier

		if let interruptionLevel = content.interruptionLevel {
			notificationContent.interruptionLevel = interruptionLevel
		}

		if let relevanceScore = content.relevanceScore {
			notificationContent.relevanceScore = relevanceScore
		}

		return notificationContent
	}
}

// MARK: - Supporting Protocols

public protocol NotificationSettingsProvider: Sendable {
	func getSettings() async -> UNNotificationSettings
}

public struct DefaultNotificationSettingsProvider: NotificationSettingsProvider {
	private let center: UNUserNotificationCenter

	public init(center: UNUserNotificationCenter = .current()) {
		self.center = center
	}

	public func getSettings() async -> UNNotificationSettings {
		await center.notificationSettings()
	}
}

// MARK: - Convenience Extensions

public extension NotificationRequest {
	static func immediate(
		title: String,
		body: String,
		sound: UNNotificationSound? = .default,
		badge: NSNumber? = nil
	) -> NotificationRequest {
		let content = NotificationContent(
			title: title,
			body: body,
			badge: badge,
			sound: sound
		)
		return NotificationRequest(content: content)
	}

	static func timed(
		interval: TimeInterval,
		title: String,
		body: String,
		sound: UNNotificationSound? = .default
	) -> NotificationRequest {
		let content = NotificationContent(
			title: title,
			body: body,
			sound: sound
		)
		let trigger = UNTimeIntervalNotificationTrigger(timeInterval: interval, repeats: false)
		return NotificationRequest(content: content, trigger: trigger)
	}
}

// MARK: - Global Convenience (Optional - for backward compatibility)

public enum LocalNotificationService {
	private static let service = DefaultNotificationService()

	public static func schedule(
		id: String = UUID().uuidString,
		title: String,
		body: String,
		sound: UNNotificationSound? = .default,
		badge: NSNumber? = nil,
		trigger: UNNotificationTrigger? = nil
	) async {
		let content = NotificationContent(
			id: id,
			title: title,
			body: body,
			badge: badge,
			sound: sound
		)

		let request = NotificationRequest(
			content: content,
			trigger: trigger
		)

		await service.schedule(request: request)
	}

	public static func sendAlert(
		id: String = UUID().uuidString,
		title: String?,
		subtitle: String = "",
		body: String = ""
	) async {
		await service.sendAlert(
			title: title ?? "",
			subtitle: subtitle,
			body: body
		)
	}
}
