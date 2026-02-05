//
//  LocationTool+Utilities.swift
//

import CoreLocation
import MapKit
import FoundationModels

extension LocationTool {
    func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter.string(from: date)
    }
}

struct AuthorizationResult {
    let status: CLAuthorizationStatus
    let isAuthorized: Bool
    let result: GeneratedContent?

    init(
        status: CLAuthorizationStatus,
        isAuthorized: Bool,
        result: GeneratedContent? = nil
    ) {
        self.status = status
        self.isAuthorized = isAuthorized
        self.result = result
    }
}

enum LocationResultSource {
    case live
    case cached

    func message(for address: String) -> String {
        switch self {
        case .live:
            return "Current location: \(address)"
        case .cached:
            return "Last known location: \(address)"
        }
    }

    var note: String? {
        switch self {
        case .live:
            return nil
        case .cached:
            return "Using last known location while waiting for a precise update."
        }
    }

    var identifier: String {
        switch self {
        case .live:
            return "live"
        case .cached:
            return "cached"
        }
    }
}

extension Double {
    var degreesToRadians: Double { self * .pi / 180 }
    var radiansToDegrees: Double { self * 180 / .pi }
}

enum LocationError: Error, LocalizedError {
    case invalidAction
    case authorizationDenied
    case authorizationNotDetermined
    case locationServicesDisabled
    case locationUnavailable
    case locationTimeout
    case operationInProgress
    case missingAddress
    case missingCoordinates
    case missingSearchQuery
    case geocodingFailed
    case reverseGeocodingFailed

    var errorDescription: String? {
        switch self {
        case .invalidAction:
            return "Invalid action. Use 'current', 'geocode', 'reverse', 'search', or 'distance'."
        case .authorizationDenied:
            return "Location access denied. Please grant permission in Settings."
        case .authorizationNotDetermined:
            return "Location permission not yet determined. Please grant permission when prompted."
        case .locationServicesDisabled:
            return "Location services are disabled. Enable Location Services to continue."
        case .locationUnavailable:
            return "Current location is unavailable."
        case .locationTimeout:
            return "Timed out while waiting for an updated location."
        case .operationInProgress:
            return "A location request is already in progress."
        case .missingAddress:
            return "Address is required for geocoding."
        case .missingCoordinates:
            return "Latitude and longitude are required."
        case .missingSearchQuery:
            return "Search query is required."
        case .geocodingFailed:
            return "Failed to find location for the given address."
        case .reverseGeocodingFailed:
            return "Failed to find address for the given coordinates."
        }
    }
}
