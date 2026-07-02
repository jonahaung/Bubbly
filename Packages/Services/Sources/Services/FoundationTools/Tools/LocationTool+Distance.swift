// © 2026 Aung Ko Min

import CoreLocation
import FoundationModels

extension LocationTool {
    func calculateDistance(arguments: Arguments) -> GeneratedContent {
        guard let lat1 = arguments.latitude,
              let lon1 = arguments.longitude,
              let lat2 = arguments.latitude2,
              let lon2 = arguments.longitude2 else
        {
            return createErrorOutput(error: LocationError.missingCoordinates)
        }

        let location1 = CLLocation(latitude: lat1, longitude: lon1)
        let location2 = CLLocation(latitude: lat2, longitude: lon2)

        let distance = location1.distance(from: location2)

        let bearing = calculateBearing(from: location1, destination: location2)
        let direction = compassDirection(from: bearing)

        return GeneratedContent(properties: [
            "status": "success",
            "location1_latitude": lat1,
            "location1_longitude": lon1,
            "location2_latitude": lat2,
            "location2_longitude": lon2,
            "distanceMeters": distance,
            "distanceKilometers": distance / 1000,
            "distanceMiles": distance / 1609.344,
            "formattedDistance": formatDistance(distance),
            "bearing": bearing,
            "direction": direction,
            "message": "Distance: \(formatDistance(distance)) \(direction)",
        ])
    }

    func formatDistance(_ meters: Double) -> String {
        if meters < 1000 {
            String(format: "%.0f meters", meters)
        } else if meters < 10000 {
            String(format: "%.1f km", meters / 1000)
        } else {
            String(format: "%.0f km", meters / 1000)
        }
    }

    func calculateBearing(from: CLLocation, destination: CLLocation) -> Double {
        let lat1 = from.coordinate.latitude.degreesToRadians
        let lon1 = from.coordinate.longitude.degreesToRadians
        let lat2 = destination.coordinate.latitude.degreesToRadians
        let lon2 = destination.coordinate.longitude.degreesToRadians

        let deltaLongitude = lon2 - lon1

        let intermediateY = sin(deltaLongitude) * cos(lat2)
        let intermediateX = cos(lat1) * sin(lat2) - sin(lat1) * cos(lat2) * cos(deltaLongitude)

        let radiansBearing = atan2(intermediateY, intermediateX)
        let degreesBearing = radiansBearing.radiansToDegrees

        return (degreesBearing + 360).truncatingRemainder(dividingBy: 360)
    }

    func compassDirection(from bearing: Double) -> String {
        let directions = [
            "N", "NNE", "NE", "ENE", "E", "ESE", "SE", "SSE",
            "S", "SSW", "SW", "WSW", "W", "WNW", "NW", "NNW",
        ]
        let index = Int((bearing + 11.25) / 22.5) % 16
        return directions[index]
    }
}
