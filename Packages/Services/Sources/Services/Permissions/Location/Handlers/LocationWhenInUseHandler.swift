// © 2026 Aung Ko Min

import Foundation
import MapKit

final class LocationWhenInUseHandler: NSObject, CLLocationManagerDelegate {
    lazy var locationManager: CLLocationManager = .init()

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        completionHandler()
    }

    var completionHandler: () -> Void = {}

    func requestPermission(_ completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler

        let status: CLAuthorizationStatus
        if #available(iOS 14.0, *) {
            status = locationManager.authorizationStatus
        } else {
            status = type(of: locationManager).authorizationStatus()
        }

        switch status {
        case .notDetermined:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        case .authorizedWhenInUse:
            locationManager.delegate = self
            locationManager.requestWhenInUseAuthorization()
        default:
            self.completionHandler()
        }
    }

    nonisolated(unsafe) static var shared: LocationWhenInUseHandler? = nil

    override init() {
        super.init()
    }

    deinit {
        locationManager.delegate = nil
    }
}
