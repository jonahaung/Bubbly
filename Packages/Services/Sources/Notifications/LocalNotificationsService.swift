import Foundation
@preconcurrency import UserNotifications

// MARK: - Abstractions

protocol NotificationScheduler {
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
	func add(_ request: UNNotificationRequest) async throws
}

extension UNUserNotificationCenter: NotificationScheduler {
	func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
		try await withCheckedThrowingContinuation { continuation in
			self.requestAuthorization(options: options) { granted, error in
				if let error { continuation.resume(throwing: error) } else { continuation.resume(returning: granted) }
			}
		}
	}

	func add(_ request: UNNotificationRequest) async throws {
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

// MARK: - Notification Content Config

public struct NotificationContentConfig {
	public let id: String
	public let title: String
	public let subtitle: String
	public let body: String
	public let badge: NSNumber?
	public let sound: UNNotificationSound?
	public let launchImageName: String?
	public let userInfo: [AnyHashable: Any]
	public let attachments: [UNNotificationAttachment]
	public let categoryIdentifier: String?
	public let threadIdentifier: String?
	public let targetContentIdentifier: String?
	public let interruptionLevel: UNNotificationInterruptionLevel?
	public let relevanceScore: Double?
	public let options: UNAuthorizationOptions
	public let trigger: (() -> UNNotificationTrigger)?

	public init(
		id: String = UUID().uuidString,
		title: String,
		subtitle: String = "",
		body: String = "",
		badge: NSNumber? = nil,
		sound: UNNotificationSound? = .default,
		launchImageName: String? = nil,
		userInfo: [AnyHashable: Any] = [:],
		attachments: [UNNotificationAttachment] = [],
		categoryIdentifier: String? = nil,
		threadIdentifier: String? = nil,
		targetContentIdentifier: String? = nil,
		interruptionLevel: UNNotificationInterruptionLevel? = nil,
		relevanceScore: Double? = nil,
		options: UNAuthorizationOptions = [],
		trigger: (() -> UNNotificationTrigger)? = nil
	) {
		self.id = id
		self.title = title
		self.subtitle = subtitle
		self.body = body
		self.badge = badge
		self.sound = sound
		self.launchImageName = launchImageName
		self.userInfo = userInfo
		self.attachments = attachments
		self.categoryIdentifier = categoryIdentifier
		self.threadIdentifier = threadIdentifier
		self.targetContentIdentifier = targetContentIdentifier
		self.interruptionLevel = interruptionLevel
		self.relevanceScore = relevanceScore
		self.options = options
		self.trigger = trigger
	}
}

// MARK: - Local Notification Service

public enum LocalNotificationService {

	// MARK: Public API (Async)
	public static func schedule(
		id: String = UUID().uuidString,
		title: String,
		body: String,
		sound: UNNotificationSound? = .default,
		badge: NSNumber? = nil,
		trigger: (() -> UNNotificationTrigger)? = nil
	) async {
		let config = NotificationContentConfig(
			id: id,
			title: title,
			body: body,
			badge: badge,
			sound: sound,
			trigger: trigger
		)
		await post(config: config)
	}

	public static func sendAlert(
		id: String = UUID().uuidString,
		title: String?,
		subtitle: String = "",
		body: String = ""
	) async {
		await schedule(
			id: id,
			title: title ?? "",
			body: body,
			sound: nil,
			trigger: nil
		)
	}

	
	public static func post(config: NotificationContentConfig) async {
		await _post(config: config)
	}

	// MARK: Private

	private static func _post(
		config: NotificationContentConfig,
		scheduler: NotificationScheduler = UNUserNotificationCenter.current()
	) async {
		let options = buildOptions(from: config)

		do {
			let granted = try await scheduler.requestAuthorization(options: options)
			guard granted else {
				debugPrint("Authorization not granted")
				return
			}

			let content = makeContent(from: config)
			let request = UNNotificationRequest(
				identifier: config.id,
				content: content,
				trigger: config.trigger?()
			)

			try await scheduler.add(request)
			debugPrint("Notification scheduled successfully")

		} catch {
			debugPrint("Failed to schedule notification: \(error.localizedDescription)")
		}
	}

	private static func buildOptions(from config: NotificationContentConfig) -> UNAuthorizationOptions {
		var opts = config.options
		if config.badge != nil { opts.insert(.badge) }
		if config.sound != nil { opts.insert(.sound) }
		if config.sound == .defaultCritical { opts.insert(.criticalAlert) }
		opts.insert(.alert)
		return opts
	}

	private static func makeContent(from config: NotificationContentConfig) -> UNNotificationContent {
		let content = UNMutableNotificationContent()
		content.title = config.title
		content.subtitle = config.subtitle
		content.body = config.body
		content.badge = config.badge
		content.sound = config.sound
		content.launchImageName = config.launchImageName ?? ""
		content.userInfo = config.userInfo
		content.attachments = config.attachments
		content.categoryIdentifier = config.categoryIdentifier ?? ""
		content.threadIdentifier = config.threadIdentifier ?? ""
		content.targetContentIdentifier = config.targetContentIdentifier
		if let interruptionLevel = config.interruptionLevel {
			content.interruptionLevel = interruptionLevel
		}
		if let relevanceScore = config.relevanceScore {
			content.relevanceScore = relevanceScore
		}
		return content
	}
}
