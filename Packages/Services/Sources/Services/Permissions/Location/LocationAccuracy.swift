//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Foundation
import MapKit

public extension CLLocationManager {
    func setAccuracy(_ value: LocationAccuracy) {
        desiredAccuracy = value.coreLocationAccuracy
    }
}

public enum LocationAccuracy {
    case best
    case bestForNavigation
    case nearestTenMeters
    case hundredMeters
    case kilometer
    case threeKilometers
    case reduced

    var coreLocationAccuracy: CLLocationAccuracy {
        switch self {
        case .best: kCLLocationAccuracyBest
        case .bestForNavigation: kCLLocationAccuracyBestForNavigation
        case .nearestTenMeters: kCLLocationAccuracyNearestTenMeters
        case .hundredMeters: kCLLocationAccuracyHundredMeters
        case .kilometer: kCLLocationAccuracyKilometer
        case .threeKilometers: kCLLocationAccuracyThreeKilometers
        case .reduced:
            if #available(iOS 14.0, tvOS 14.0, watchOS 7.0, *) {
                kCLLocationAccuracyReduced
            } else {
                kCLLocationAccuracyThreeKilometers
            }
        }
    }
}
