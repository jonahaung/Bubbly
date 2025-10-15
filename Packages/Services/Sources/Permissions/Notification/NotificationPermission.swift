//
//  NotificationPermission.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Foundation
import UserNotifications

public extension Permission {
	static func notification(_ access: Set<PermissionKind.NotificationAccess> = [.alert, .badge, .sound]) -> NotificationPermission {
		return NotificationPermission(access: access)
	}

}

public final class NotificationPermission: Permission {

	public let access: Set<PermissionKind.NotificationAccess>
	public var kind: PermissionKind { .notification(access: access) }

	public init(access: Set<PermissionKind.NotificationAccess>) {
		self.access = access
	}

	public var status: PermissionStatus {
		get {
			return getStatus()
		}
	}

	private func getStatus() -> PermissionStatus {
		guard let authorizationStatus = fetchAuthorizationStatusLegacy() else {
			return .notDetermined
		}
		return status(from: authorizationStatus)
	}

	private func status(from authorizationStatus: UNAuthorizationStatus) -> PermissionStatus {
		switch authorizationStatus {
		case .authorized: return .authorized
		case .denied: return .denied
		case .notDetermined: return .notDetermined
		case .provisional: return .authorized
		case .ephemeral: return .authorized
		@unknown default: return .denied
		}
	}

	private func fetchAuthorizationStatusLegacy() -> UNAuthorizationStatus? {
		final class SettingsContainer {
			var settings: UNNotificationSettings?
		}

		let container = SettingsContainer()
		let semaphore = DispatchSemaphore(value: 0)

		UNUserNotificationCenter.current().getNotificationSettings { settings in
			container.settings = settings
			semaphore.signal()
		}

		semaphore.wait()
		return container.settings?.authorizationStatus
	}

	public func request(completion: @escaping @Sendable () -> Void) {
		let center = UNUserNotificationCenter.current()
		center
			.requestAuthorization(
				options: UNAuthorizationOptions(
					access.map { $0.userNotifcationAuthorizationOptions
					})
			) { _, _ in
				DispatchQueue.main.async {
					completion()
				}
			}
	}
}
