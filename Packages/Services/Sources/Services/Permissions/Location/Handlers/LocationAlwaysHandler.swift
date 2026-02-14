import Foundation
import MapKit

class LocationAlwaysHandler: NSObject, CLLocationManagerDelegate {
	// MARK: - Location Manager

	lazy var locationManager = CLLocationManager()

	func locationManager(_: CLLocationManager,
	                     didChangeAuthorization status: CLAuthorizationStatus)
	{
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

		let status: CLAuthorizationStatus = if #available(iOS 14.0, *) {
			locationManager.authorizationStatus
		} else {
			CLLocationManager.authorizationStatus()
		}

		switch status {
		case .notDetermined:
			locationManager.delegate = self
			locationManager.requestAlwaysAuthorization()

		case .authorizedAlways:
			// Already granted
			completionHandler()

		case .authorizedWhenInUse, .denied, .restricted:
			// Handle according to your app’s policy (perhaps prompt UI)
			// You might still call requestAlwaysAuthorization() if appropriate
			locationManager.delegate = self
			locationManager.requestAlwaysAuthorization()

		@unknown default:
			break
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
