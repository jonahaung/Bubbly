//
//  LocationPermission.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import EventKit
import Foundation

public extension Permission {
	static func location(access: PermissionKind.LocationAccess) -> LocationPermission {
		LocationPermission(access: access)
	}
}

public class LocationPermission: Permission {
	private var access: PermissionKind.LocationAccess
	public var kind: PermissionKind {
		.location(access: access)
	}

	// MARK: - Init

	init(access: PermissionKind.LocationAccess) {
		self.access = access
	}

	public var status: PermissionStatus {
		let authorizationStatus: CLAuthorizationStatus = {
			let locationManager = CLLocationManager()
			return locationManager.authorizationStatus
		}()

		switch authorizationStatus {
		case .authorized: return .authorized
		case .denied: return .denied
		case .notDetermined: return .notDetermined
		case .restricted: return .denied
		case .authorizedAlways:
			if access == .always {
				return .authorized
			}
			return .denied
		case .authorizedWhenInUse:
			if access == .whenInUse {
				return .authorized
			}
			return .denied
		@unknown default: return .denied
		}
	}

	public var isPrecise: Bool {
		switch CLLocationManager().accuracyAuthorization {
		case .fullAccuracy: return true
		case .reducedAccuracy: return false
		@unknown default: return false
		}
	}

	public func request(completion: @escaping @Sendable () -> Void) {
		switch access {
		case .whenInUse:
			LocationWhenInUseHandler.shared = LocationWhenInUseHandler()
			LocationWhenInUseHandler.shared?.requestPermission {
				DispatchQueue.main.async {
					completion()
					LocationWhenInUseHandler.shared = nil
				}
			}
		case .always:
			LocationAlwaysHandler.shared = LocationAlwaysHandler()
			LocationAlwaysHandler.shared?.requestPermission {
				DispatchQueue.main.async {
					completion()
					LocationAlwaysHandler.shared = nil
				}
			}
		}
	}
}
