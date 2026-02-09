//
//  PermissionKind.swift
//  Services
//
//  Created by Aung Ko Min on 18/8/25.
//

public enum PermissionKind {
	case camera
	case notification(access: Set<NotificationAccess>)
	case photoLibrary
	case microphone
	case contacts
	case location(access: LocationAccess)
	case mediaLibrary

	public enum LocationAccess: Hashable {
		case whenInUse
		case always
	}

	public enum NotificationAccess: String, CaseIterable, Hashable {
		case badge
		case sound
		case alert
		case carPlay
		case criticalAlert
		case providesAppNotificationSettings
		case provisional
		case announcement
		case timeSensitive
	}
}

public extension PermissionKind {
	var permission: any Permission {
		switch self {
		case .camera: CameraPermission()
		case let .location(access): LocationPermission(access: access)
		case .microphone: MicrophonePermission()
		case .photoLibrary: PhotoLibraryPermission()
		case let .notification(access): NotificationPermission(access: access)
		case .contacts: ContactsPermission()
		case .mediaLibrary: MediaLibraryPermission()
		}
	}
}

public extension PermissionKind {
	var name: String {
		switch self {
		case .camera: "Camera"
		case .photoLibrary: "Photo Library"
		case .microphone: "Microphone"
		case .contacts: "Contacts"
		case let .location(access):
			access == .always ? "Location Always" : "Location When Use"
		case .mediaLibrary: "Media Library"
		case .notification: "Notifications"
		}
	}

	var usageDescriptionKey: String {
		switch self {
		case .camera: "NSCameraUsageDescription"
		case .photoLibrary: "NSPhotoLibraryUsageDescription"
		case .microphone: "NSMicrophoneUsageDescription"
		case .contacts: "NSContactsUsageDescription"
		case let .location(access):
			access == .whenInUse ? "NSLocationWhenInUseUsageDescription" : "NSLocationAlwaysAndWhenInUseUsageDescription"
		case .mediaLibrary: "NSAppleMusicUsageDescription"
		case .notification: "Notification"
		}
	}

	var description: String {
		switch self {
		case .camera: "Allow to use your camera"
		case .photoLibrary: "Allow to access your photos"
		case .microphone: "Allow to record with microphone"
		case .contacts: "Allow to access your contacts"
		case let .location(access):
			access == .whenInUse ? "Allow to access your location when in use" : "Always allow to access your location"
		case .mediaLibrary: "Allow to access your media library"
		case .notification: "Allow to send and receive notifications"
		}
	}

	var imageName: String {
		switch self {
		case .camera: "camera.fill"
		case .photoLibrary: "photo"
		case .microphone: "mic.fill"
		case .contacts: "person.crop.circle.fill"
		case .notification: "bell.badge.fill"
		case .location: "location.fill"
		case .mediaLibrary: "play.rectangle.fill"
		}
	}
}

extension PermissionKind: Hashable {
	public static func == (lhs: PermissionKind, rhs: PermissionKind) -> Bool {
		switch (lhs, rhs) {
		case (.camera, .camera): true
		case (.photoLibrary, .photoLibrary): true
		case (.microphone, .microphone): true
		case (.contacts, .contacts): true
		case (.mediaLibrary, .mediaLibrary): true
		case let (.notification(lhsAccess), .notification(rhsAccess)): lhsAccess == rhsAccess
		case let (.location(lhsAccess), .location(rhsAccess)): lhsAccess == rhsAccess
		default: false
		}
	}

	public func hash(into hasher: inout Hasher) {
		switch self {
		case .camera: hasher.combine("camera")
		case .photoLibrary: hasher.combine("photoLibrary")
		case .microphone: hasher.combine("microphone")
		case .contacts: hasher.combine("contacts")
		case .mediaLibrary: hasher.combine("mediaLibrary")
		case let .notification(access):
			hasher.combine("notification")
			hasher.combine(access)
		case let .location(access):
			hasher.combine("location")
			hasher.combine(access)
		}
	}
}
