import Foundation
import UserNotifications

public extension Permission {
	static func notification(_ access: Set<PermissionKind.NotificationAccess> = [
		.alert,
		.badge,
		.sound,
	]) -> NotificationPermission {
		NotificationPermission(access: access)
	}
}

/// Simple sendable box to move a value out of a @Sendable closure safely.
private final class _SendableBox<T>: @unchecked Sendable {
	var value: T?
	init(_ value: T? = nil) {
		self.value = value
	}
}

public final class NotificationPermission: Permission {
	public let access: Set<PermissionKind.NotificationAccess>
	public var kind: PermissionKind {
		.notification(access: access)
	}

	public init(access: Set<PermissionKind.NotificationAccess>) {
		self.access = access
	}

	public var status: PermissionStatus {
		getStatus()
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

	/// Synchronous legacy fetch used by the `status` property.
	/// Uses a Sendable box to satisfy Swift 6 concurrency checks.
	private func fetchAuthorizationStatusLegacy() -> UNAuthorizationStatus? {
		let semaphore = DispatchSemaphore(value: 0)
		let box = _SendableBox<UNAuthorizationStatus>()

		UNUserNotificationCenter.current().getNotificationSettings { settings in
			box.value = settings.authorizationStatus
			semaphore.signal()
		}

		semaphore.wait()
		return box.value
	}

	/// Modern async alternative you can adopt at call sites.
	/// Prefer this over the synchronous method above when possible.
	@available(iOS 15, macOS 12, tvOS 15, watchOS 8, *)
	public func statusAsync() async -> PermissionStatus {
		let settings = await UNUserNotificationCenter.current().notificationSettings()
		return status(from: settings.authorizationStatus)
	}

	public func request(completion: @escaping @Sendable () -> Void) {
		let center = UNUserNotificationCenter.current()
		center
			.requestAuthorization(
				options: UNAuthorizationOptions(
					access.map(\.userNotifcationAuthorizationOptions)
				)
			) { _, _ in
				DispatchQueue.main.async {
					completion()
				}
			}
	}
}
