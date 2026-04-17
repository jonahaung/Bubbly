// © 2026 Aung Ko Min

import Foundation
import UserNotifications

// MARK: - NotificationSound

public enum NotificationSound: Sendable {
    case `default`
    case none
    case named(String)
}

// MARK: - NotificationInterruptionLevel

public enum NotificationInterruptionLevel: Int, Sendable {
    case passive = 0
    case active = 1
    case timeSensitive = 2
    case critical = 3
}

// MARK: - NotificationTrigger

public enum NotificationTrigger: Sendable {
    case timeInterval(TimeInterval, repeats: Bool)
}

// MARK: - NotificationContent

public struct NotificationContent: Sendable {
    public let id: String
    public let title: String
    public let subtitle: String
    public let body: String
    public let badge: NSNumber?
    public let sound: NotificationSound?
    public let launchImageName: String?
    public let userInfo: [String: any Sendable]
    public let categoryIdentifier: String?
    public let threadIdentifier: String?
    public let targetContentIdentifier: String?
    public let interruptionLevel: NotificationInterruptionLevel?
    public let relevanceScore: Double?

    public init(
        id: String = UUID().uuidString,
        title: String,
        subtitle: String = "",
        body: String = "",
        badge: NSNumber? = nil,
        sound: NotificationSound? = .default,
        launchImageName: String? = nil,
        userInfo: [String: any Sendable] = [:],
        categoryIdentifier: String? = nil,
        threadIdentifier: String? = nil,
        targetContentIdentifier: String? = nil,
        interruptionLevel: NotificationInterruptionLevel? = nil,
        relevanceScore: Double? = nil,
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

// MARK: - NotificationRequest

public struct NotificationRequest {
    public let content: NotificationContent
    public let trigger: NotificationTrigger?
    public let authorizationOptions: UNAuthorizationOptions

    public init(
        content: NotificationContent,
        trigger: NotificationTrigger? = nil,
        authorizationOptions: UNAuthorizationOptions = [.alert, .badge, .sound],
    ) {
        self.content = content
        self.trigger = trigger
        self.authorizationOptions = authorizationOptions
    }
}

// MARK: - NotificationScheduler

@MainActor
public protocol NotificationScheduler {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func add(_ request: UNNotificationRequest) async throws
}

// MARK: - UNUserNotificationCenter + NotificationScheduler

extension UNUserNotificationCenter: NotificationScheduler {
    public func add(_ request: UNNotificationRequest) async throws {
        try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<
            Void,
            Error,
        >) in
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

// MARK: - NotificationService

@MainActor
public protocol NotificationService {
    func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool
    func schedule(request: NotificationRequest) async
    func sendAlert(title: String, subtitle: String, body: String) async
}

// MARK: - DefaultNotificationService

@MainActor
public final class DefaultNotificationService: NotificationService {
    private let scheduler: NotificationScheduler
    private let settingsProvider: NotificationSettingsProvider

    public init(
        scheduler: NotificationScheduler = UNUserNotificationCenter.current(),
        settingsProvider: NotificationSettingsProvider =
            DefaultNotificationSettingsProvider(
            ),
    ) {
        self.scheduler = scheduler
        self.settingsProvider = settingsProvider
    }

    public func requestAuthorization(options: UNAuthorizationOptions) async throws -> Bool {
        try await scheduler
            .requestAuthorization(
                options: options,
            )
    }

    public func schedule(
        request: NotificationRequest,
    ) async {
        do {
            let settings = await settingsProvider.getSettings()
            guard canSchedule(request: request, settings: settings) else {
                return
            }

            try await scheduler.add(makeRequest(from: request))
        } catch {
            return
        }
    }

    public func sendAlert(
        title: String,
        subtitle: String = "",
        body: String = "",
    ) async {
        let content = NotificationContent(
            title: title,
            subtitle: subtitle,
            body: body,
            sound: nil,
        )

        let request = NotificationRequest(
            content: content,
            authorizationOptions: [.alert],
        )

        await schedule(
            request: request,
        )
    }

    // MARK: - Private Helpers

    private func makeContent(from content: NotificationContent) -> UNMutableNotificationContent {
        let notificationContent = UNMutableNotificationContent()
        notificationContent.title = content.title
        notificationContent.subtitle = content.subtitle
        notificationContent.body = content.body
        notificationContent.badge = content.badge
        notificationContent.sound = makeSound(from: content.sound)
        if let launchImageName = content.launchImageName {
            notificationContent.launchImageName = launchImageName
        }
        if !content.userInfo.isEmpty {
            notificationContent.userInfo = content.userInfo
                .reduce(into: [AnyHashable: Any]()) { result, item in
                    result[item.key] = item.value
                }
        }
        if let categoryIdentifier = content.categoryIdentifier {
            notificationContent.categoryIdentifier = categoryIdentifier
        }
        if let threadIdentifier = content.threadIdentifier {
            notificationContent.threadIdentifier = threadIdentifier
        }
        notificationContent.targetContentIdentifier = content.targetContentIdentifier

        if let interruptionLevel = content.interruptionLevel {
            if let mapped = UNNotificationInterruptionLevel(
                rawValue: UInt(interruptionLevel.rawValue),
            ) {
                notificationContent.interruptionLevel = mapped
            }
        }

        if let relevanceScore = content.relevanceScore {
            notificationContent.relevanceScore = relevanceScore
        }

        return notificationContent
    }

    private func makeRequest(from request: NotificationRequest) -> UNNotificationRequest {
        UNNotificationRequest(
            identifier: request.content.id,
            content: makeContent(from: request.content),
            trigger: makeTrigger(from: request.trigger),
        )
    }

    private func makeTrigger(from trigger: NotificationTrigger?) -> UNNotificationTrigger? {
        guard let trigger else {
            return nil
        }

        switch trigger {
        case let .timeInterval(interval, repeats):
            return UNTimeIntervalNotificationTrigger(
                timeInterval: interval,
                repeats: repeats,
            )
        }
    }

    private func makeSound(from sound: NotificationSound?) -> UNNotificationSound? {
        guard let sound else {
            return nil
        }

        switch sound {
        case .none:
            return nil
        case .default:
            return UNNotificationSound.default
        case let .named(name):
            return UNNotificationSound(named: UNNotificationSoundName(rawValue: name))
        }
    }

    private func canSchedule(
        request: NotificationRequest,
        settings: UNNotificationSettings,
    ) -> Bool {
        guard settings.authorizationStatus == .authorized else {
            return false
        }

        if request.authorizationOptions.contains(.alert),
           settings.alertSetting != .enabled
        {
            return false
        }
        if request.authorizationOptions.contains(.badge),
           settings.badgeSetting != .enabled
        {
            return false
        }
        if request.authorizationOptions.contains(.sound),
           settings.soundSetting != .enabled
        {
            return false
        }
        return true
    }
}

// MARK: - NotificationSettingsProvider

@MainActor
public protocol NotificationSettingsProvider {
    func getSettings() async -> UNNotificationSettings
}

// MARK: - DefaultNotificationSettingsProvider

@MainActor
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
        sound: NotificationSound? = .default,
        badge: NSNumber? = nil,
    ) -> NotificationRequest {
        let content = NotificationContent(
            title: title,
            body: body,
            badge: badge,
            sound: sound,
        )
        return NotificationRequest(content: content)
    }

    static func timed(
        interval: TimeInterval,
        title: String,
        body: String,
        sound: NotificationSound? = .default,
        repeats: Bool = false,
    ) -> NotificationRequest {
        let content = NotificationContent(
            title: title,
            body: body,
            sound: sound,
        )
        let trigger = NotificationTrigger.timeInterval(
            interval,
            repeats: repeats,
        )
        return NotificationRequest(
            content: content,
            trigger: trigger,
        )
    }
}

// MARK: - LocalNotificationService

public enum LocalNotificationService {
    // Create and use the @MainActor service on the main actor when needed.

    public static func schedule(
        id: String,
        title: String,
        body: String,
        sound: NotificationSound? = .default,
        badge: NSNumber? = nil,
        trigger: NotificationTrigger? = nil,
    ) async {
        let content = NotificationContent(
            id: id,
            title: title,
            body: body,
            badge: badge,
            sound: sound,
        )

        let request = NotificationRequest(
            content: content,
            trigger: trigger,
        )

        await MainActor.run {
            let service = DefaultNotificationService()
            Task { await service.schedule(request: request) }
        }
    }

    public static func schedule(
        title: String,
        body: String,
        sound: NotificationSound? = .default,
        badge: NSNumber? = nil,
        trigger: NotificationTrigger? = nil,
    ) async {
        await schedule(
            id: UUID().uuidString,
            title: title,
            body: body,
            sound: sound,
            badge: badge,
            trigger: trigger,
        )
    }

    public static func sendAlert(
        id _: String = UUID().uuidString,
        title: String?,
        subtitle: String = "",
        body: String = "",
    ) async {
        await MainActor.run {
            let service = DefaultNotificationService()
            Task { await service.sendAlert(title: title ?? "", subtitle: subtitle, body: body) }
        }
    }
}
