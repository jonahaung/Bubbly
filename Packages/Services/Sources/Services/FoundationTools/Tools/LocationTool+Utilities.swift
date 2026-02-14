import CoreLocation
import FoundationModels
import MapKit

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

	init(status: CLAuthorizationStatus,
	     isAuthorized: Bool,
	     result: GeneratedContent? = nil)
	{
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
			"Current location: \(address)"
		case .cached:
			"Last known location: \(address)"
		}
	}

	var note: String? {
		switch self {
		case .live:
			nil
		case .cached:
			"Using last known location while waiting for a precise update."
		}
	}

	var identifier: String {
		switch self {
		case .live:
			"live"
		case .cached:
			"cached"
		}
	}
}

extension Double {
	var degreesToRadians: Double {
		self * .pi / 180
	}

	var radiansToDegrees: Double {
		self * 180 / .pi
	}
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
			"Invalid action. Use 'current', 'geocode', 'reverse', 'search', or 'distance'."
		case .authorizationDenied:
			"Location access denied. Please grant permission in Settings."
		case .authorizationNotDetermined:
			"Location permission not yet determined. Please grant permission when prompted."
		case .locationServicesDisabled:
			"Location services are disabled. Enable Location Services to continue."
		case .locationUnavailable:
			"Current location is unavailable."
		case .locationTimeout:
			"Timed out while waiting for an updated location."
		case .operationInProgress:
			"A location request is already in progress."
		case .missingAddress:
			"Address is required for geocoding."
		case .missingCoordinates:
			"Latitude and longitude are required."
		case .missingSearchQuery:
			"Search query is required."
		case .geocodingFailed:
			"Failed to find location for the given address."
		case .reverseGeocodingFailed:
			"Failed to find address for the given coordinates."
		}
	}
}
