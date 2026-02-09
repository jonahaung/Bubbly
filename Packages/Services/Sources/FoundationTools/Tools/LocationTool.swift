//
//  LocationTool.swift
//  FoundationLab
//
//  Created by Rudrank Riyam on 6/17/25.
//

@preconcurrency import CoreLocation
import Foundation
import FoundationModels
@preconcurrency import MapKit

/// A tool for location services and geocoding using CoreLocation and MapKit.
///
/// Use `LocationTool` to access current location, geocoding, reverse geocoding,
/// place search, and distance calculations between coordinates.
///
/// The following actions are supported:
/// - `current`: Get the device's current location
/// - `geocode`: Convert an address to coordinates
/// - `reverse`: Convert coordinates to an address
/// - `search`: Search for nearby places
/// - `distance`: Calculate distance between two coordinate pairs
///
/// ```swift
/// let session = LanguageModelSession(tools: [LocationTool()])
/// let response = try await session.respond(to: "Where is Apple Park located?")
/// ```
///
/// - Important: Requires Location Services capability, `NSLocationWhenInUseUsageDescription`
///   in Info.plist, and user permission at runtime.
public struct LocationTool: Tool {
	/// The name of the tool, used for identification.
	public let name = "accessLocation"
	/// A brief description of the tool's functionality.
	public let description =
		"Get current location, geocode addresses, search places, and calculate distances"

	/// Arguments for location operations.
	@Generable
	public struct Arguments {
		/// The action to perform: "current", "geocode", "reverse", "search", "distance"
		@Guide(
			description: "The action to perform: 'current', 'geocode', 'reverse', 'search', 'distance'"
		)
		public var action: String

		/// Address to geocode (for geocode action)
		@Guide(description: "Address to geocode (for geocode action)")
		public var address: String?

		/// Latitude for reverse geocoding or distance calculation
		@Guide(description: "Latitude for reverse geocoding or distance calculation")
		public var latitude: Double?

		/// Longitude for reverse geocoding or distance calculation
		@Guide(description: "Longitude for reverse geocoding or distance calculation")
		public var longitude: Double?

		/// Second latitude for distance calculation
		@Guide(description: "Second latitude for distance calculation")
		public var latitude2: Double?

		/// Second longitude for distance calculation
		@Guide(description: "Second longitude for distance calculation")
		public var longitude2: Double?

		/// Search query for places (for search action)
		@Guide(description: "Search query for places (for search action)")
		public var searchQuery: String?

		/// Search radius in meters (defaults to 1000)
		@Guide(description: "Search radius in meters (defaults to 1000)")
		public var radius: Double?

		public init(action: String = "",
		            address: String? = nil,
		            latitude: Double? = nil,
		            longitude: Double? = nil,
		            latitude2: Double? = nil,
		            longitude2: Double? = nil,
		            searchQuery: String? = nil,
		            radius: Double? = nil)
		{
			self.action = action
			self.address = address
			self.latitude = latitude
			self.longitude = longitude
			self.latitude2 = latitude2
			self.longitude2 = longitude2
			self.searchQuery = searchQuery
			self.radius = radius
		}
	}

	let locationManager = CLLocationManager()

	public init() {
		locationManager.desiredAccuracy = kCLLocationAccuracyBest
		locationManager.distanceFilter = kCLDistanceFilterNone
	}

	public func call(arguments: Arguments) async throws -> GeneratedContent {
		switch arguments.action.lowercased() {
		case "current":
			return await getCurrentLocation()

		case "geocode":
			// Pending: ensure geocodeAddress returns GeneratedContent or wrap its result here
			return await geocodeAddress(address: arguments.address)

		case "reverse":
			// Build CLLocation from provided latitude/longitude and use reverseGeocode(location:)
			guard let lat = arguments.latitude, let lon = arguments.longitude else {
				return createErrorOutput(error: LocationError.missingCoordinates)
			}
			let location = CLLocation(latitude: lat, longitude: lon)
			let mapItem = await reverseGeocode(location: location)
			// Convert MKMapItem? to a user-facing address string and GeneratedContent
			let address = formatAddress(from: mapItem, fallbackLocation: location)
			return GeneratedContent(properties: [
				"status": "success",
				"latitude": lat,
				"longitude": lon,
				"address": address,
				"message": "Reverse geocoded location",
			])

		case "search":
			// Pending: ensure searchPlaces returns GeneratedContent or wrap its result here
			return await searchPlaces(query: arguments.searchQuery, radius: arguments.radius)

		case "distance":
			return calculateDistance(arguments: arguments)

		default:
			return createErrorOutput(error: LocationError.invalidAction)
		}
	}
}
