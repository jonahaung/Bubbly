//
//  LocationAlwaysHandler.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Foundation
import MapKit

class LocationAlwaysHandler: NSObject, CLLocationManagerDelegate {

	// MARK: - Location Manager

	lazy var locationManager = CLLocationManager()

	func locationManager(_ manager: CLLocationManager, didChangeAuthorization status: CLAuthorizationStatus) {
		if status == .notDetermined {
			return
		}
		completionHandler()
	}

	@available(iOS 14.0, *)
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if manager.authorizationStatus == .notDetermined {
			return
		}
		completionHandler()
	}

	// MARK: - Process

	var completionHandler: () -> Void = {}

	func requestPermission(_ completionHandler: @escaping () -> Void) {
		self.completionHandler = completionHandler

		let status = CLLocationManager.authorizationStatus()

		switch status {
		case .notDetermined:
			locationManager.delegate = self
			locationManager.requestAlwaysAuthorization()
		case .authorizedWhenInUse:
			locationManager.delegate = self
			locationManager.requestAlwaysAuthorization()
		default:
			self.completionHandler()
		}
	}

	nonisolated(unsafe) static var shared: LocationAlwaysHandler?

	override init() {
		super.init()
	}

	deinit {
		locationManager.delegate = nil
	}
}
