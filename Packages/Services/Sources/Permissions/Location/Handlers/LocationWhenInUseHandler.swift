//
//  LocationWhenInUseHandler.swift
//  Services
//
//  Created by Aung Ko Min on 17/8/25.
//

import Foundation
import MapKit

class LocationWhenInUseHandler: NSObject, CLLocationManagerDelegate {
    lazy var locationManager = CLLocationManager()

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        if manager.authorizationStatus == .notDetermined {
            return
        }
        completionHandler()
    }

    var completionHandler: () -> Void = {}

    func requestPermission(_ completionHandler: @escaping () -> Void) {
        self.completionHandler = completionHandler

        let status: CLAuthorizationStatus = CLLocationManager.authorizationStatus()

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

    nonisolated(unsafe) static var shared: LocationWhenInUseHandler?

    override init() {
        super.init()
    }

    deinit {
        locationManager.delegate = nil
    }
}
