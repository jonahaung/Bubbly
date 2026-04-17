// © 2026 Aung Ko Min

import CoreLocation
import FoundationModels
import MapKit

extension LocationTool {
    func searchPlaces(query: String?, radius: Double?) async -> GeneratedContent {
        guard let query, !query.isEmpty else {
            return createErrorOutput(error: LocationError.missingSearchQuery)
        }

        let request = MKLocalSearch.Request()
        request.naturalLanguageQuery = query

        if let location = locationManager.location {
            let searchRadius = radius ?? 1000
            request.region = MKCoordinateRegion(
                center: location.coordinate,
                latitudinalMeters: searchRadius * 2,
                longitudinalMeters: searchRadius * 2,
            )
        }

        let search = MKLocalSearch(request: request)

        do {
            let response = try await search.start()

            var placesDescription = ""

            for (index, item) in response.mapItems.prefix(10).enumerated() {
                let distance: String
                if let userLocation = locationManager.location {
                    let placeLocation = CLLocation(
                        latitude: item.location.coordinate.latitude,
                        longitude: item.location.coordinate.longitude,
                    )
                    let meters = userLocation.distance(from: placeLocation)
                    distance = formatDistance(meters)
                } else {
                    distance = "Unknown distance"
                }

                placesDescription += "\(index + 1). \(item.name ?? "Unknown Place")\n"
                placesDescription += "   Address: \(formatMapItemAddress(item))\n"
                placesDescription += "   Distance: \(distance)\n"
                if let phone = item.phoneNumber {
                    placesDescription += "   Phone: \(phone)\n"
                }
                placesDescription += "\n"
            }

            if placesDescription.isEmpty {
                placesDescription = "No places found matching '\(query)'"
            }

            return GeneratedContent(properties: [
                "status": "success",
                "query": query,
                "resultCount": response.mapItems.count,
                "places": placesDescription.trimmingCharacters(in: .whitespacesAndNewlines),
                "message": "Found \(response.mapItems.count) place(s)",
            ])
        } catch {
            return createErrorOutput(error: error)
        }
    }

    func formatMapItemAddress(_ mapItem: MKMapItem?) -> String {
        formatAddress(from: mapItem, fallbackLocation: mapItem?.location)
    }
}
