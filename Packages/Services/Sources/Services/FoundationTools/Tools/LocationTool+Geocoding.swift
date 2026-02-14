import CoreLocation
import FoundationModels
import MapKit

extension LocationTool {
	func reverseGeocode(location: CLLocation) async -> MKMapItem? {
		guard let request = MKReverseGeocodingRequest(location: location) else {
			return nil
		}
		return try? await request.mapItems.first
	}

	func geocodeAddress(address: String?) async -> GeneratedContent {
		guard let address, !address.isEmpty else {
			return createErrorOutput(error: LocationError.missingAddress)
		}

		do {
			guard let request = MKGeocodingRequest(addressString: address) else {
				return createErrorOutput(error: LocationError.geocodingFailed)
			}

			let mapItems = try await request.mapItems
			guard let mapItem = mapItems.first else {
				return createErrorOutput(error: LocationError.geocodingFailed)
			}

			let formattedAddress = formatAddress(from: mapItem, fallbackLocation: mapItem.location)
			let location = mapItem.location

			return GeneratedContent(properties: [
				"status": "success",
				"query": address,
				"latitude": location.coordinate.latitude,
				"longitude": location.coordinate.longitude,
				"formattedAddress": formattedAddress,
				"message": "Location found: \(formattedAddress)",
			])
		} catch {
			return createErrorOutput(error: error)
		}
	}

	func reverseGeocode(latitude: Double?, longitude: Double?) async -> GeneratedContent {
		guard let latitude,
		      let longitude
		else {
			return createErrorOutput(error: LocationError.missingCoordinates)
		}

		let location = CLLocation(latitude: latitude, longitude: longitude)

		do {
			guard let request = MKReverseGeocodingRequest(location: location) else {
				return createErrorOutput(error: LocationError.reverseGeocodingFailed)
			}
			let mapItems = try await request.mapItems

			guard let mapItem = mapItems.first else {
				return createErrorOutput(error: LocationError.reverseGeocodingFailed)
			}

			let address = formatAddress(from: mapItem, fallbackLocation: location)

			return GeneratedContent(properties: [
				"status": "success",
				"latitude": latitude,
				"longitude": longitude,
				"address": address,
				"message": "Address: \(address)",
			])
		} catch {
			return createErrorOutput(error: error)
		}
	}
}

// MARK: - Address Formatting

func formatAddress(from mapItem: MKMapItem?,
                   fallbackLocation: CLLocation?) -> String
{
	guard let mapItem else {
		return fallbackLocation.map(coordinateDescription) ?? "Unknown location"
	}
	return mapItem.address?.fullAddress ?? mapItem.name ?? "Unknown location"
}

func coordinateDescription(for location: CLLocation) -> String {
	String(
		format: "%.4f, %.4f",
		location.coordinate.latitude,
		location.coordinate.longitude
	)
}
