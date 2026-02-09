//
//  PhotoLibraryPermission.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Photos

public extension Permission {
	static var photoLibrary: PhotoLibraryPermission {
		PhotoLibraryPermission()
	}
}

public class PhotoLibraryPermission: Permission {
	open var kind: PermissionKind {
		.photoLibrary
	}

	open var fullAccessUsageDescriptionKey: String? {
		"NSPhotoLibraryUsageDescription"
	}

	open var addingOnlyUsageDescriptionKey: String? {
		"NSPhotoLibraryAddUsageDescription"
	}

	public var status: PermissionStatus {
		switch PHPhotoLibrary.authorizationStatus() {
		case .authorized: return .authorized
		case .denied: return .denied
		case .notDetermined: return .notDetermined
		case .restricted: return .denied
		case .limited: return .authorized
		@unknown default: return .denied
		}
	}

	public func request(completion: @escaping @Sendable () -> Void) {
		PHPhotoLibrary.requestAuthorization {
			_ in
			DispatchQueue.main.async {
				completion()
			}
		}
	}
}
