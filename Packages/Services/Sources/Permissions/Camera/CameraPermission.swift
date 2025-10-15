//
//  CameraPermission.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Foundation
import AVFoundation

public extension Permission {
	static var camera: CameraPermission {
		return CameraPermission()
	}
}

public class CameraPermission: Permission {

	public var kind: PermissionKind { .camera }

	public var status: PermissionStatus {
		switch AVCaptureDevice.authorizationStatus(for: AVMediaType.video) {
		case .authorized: return .authorized
		case .denied: return .denied
		case .notDetermined: return .notDetermined
		case .restricted: return .denied
		@unknown default: return .denied
		}
	}

	public func request(completion: @escaping @Sendable () -> Void) {
		AVCaptureDevice.requestAccess(for: AVMediaType.video, completionHandler: {
			_ in
			DispatchQueue.main.async {
				completion()
			}
		})
	}
}
