@preconcurrency import CoreLocation
import FoundationModels
import MapKit

extension LocationTool {
	func getCurrentLocation() async -> GeneratedContent {
		let authorization = await checkLocationAuthorization()

		if !authorization.isAuthorized {
			if authorization.status == .notDetermined {
				return await requestLocationPermission()
			}

			if let message = authorization.result {
				return message
			}

			return createErrorOutput(error: LocationError.authorizationDenied)
		}

		do {
			let location = try await requestLiveLocation()
			return await buildCurrentLocationContent(from: location, source: .live)
		} catch {
			if let cached = await cachedLocation() {
				return await buildCurrentLocationContent(from: cached, source: .cached)
			}

			if let locationError = error as? LocationError {
				return createErrorOutput(error: locationError)
			}

			return createErrorOutput(error: error)
		}
	}

	func buildCurrentLocationContent(from location: CLLocation,
	                                 source: LocationResultSource) async -> GeneratedContent
	{
		let mapItem = await reverseGeocode(location: location)
		let address = formatAddress(from: mapItem, fallbackLocation: location)

		return GeneratedContent(properties: [
			"status": "success",
			"source": source.identifier,
			"latitude": location.coordinate.latitude,
			"longitude": location.coordinate.longitude,
			"altitude": location.altitude,
			"accuracy": location.horizontalAccuracy,
			"timestamp": formatDate(location.timestamp),
			"address": address,
			"message": source.message(for: address),
			"note": source.note ?? "",
		])
	}

	@MainActor
	func cachedLocation() -> CLLocation? {
		locationManager.location
	}

	@MainActor
	func requestLiveLocation(timeout: TimeInterval = 8) async throws -> CLLocation {
		let fetcher = CurrentLocationFetcher()
		return try await fetcher.requestLocation(using: locationManager, timeout: timeout)
	}

	func requestLocationPermission() async -> GeneratedContent {
		let permissionRequester = PermissionRequester()
		locationManager.delegate = permissionRequester

		#if os(macOS)
			locationManager.startUpdatingLocation()
			locationManager.stopUpdatingLocation()
		#else
			locationManager.requestWhenInUseAuthorization()
		#endif

		await permissionRequester.waitForAuthorizationResponse()

		let authorization = await checkLocationAuthorization()
		if authorization.isAuthorized {
			return await getCurrentLocation()
		} else {
			return createErrorOutput(error: LocationError.authorizationDenied)
		}
	}

	func createErrorOutput(error: Error) -> GeneratedContent {
		GeneratedContent(properties: [
			"status": "error",
			"error": error.localizedDescription,
			"message": "Failed to perform location operation",
		])
	}

	@MainActor
	func checkLocationAuthorization() -> AuthorizationResult {
		let status = locationManager.authorizationStatus

		guard CLLocationManager.locationServicesEnabled() else {
			return AuthorizationResult(
				status: status,
				isAuthorized: false,
				result: createErrorOutput(error: LocationError.locationServicesDisabled)
			)
		}

		#if os(iOS) || os(visionOS)
			if status == .authorizedAlways || status == .authorizedWhenInUse {
				return AuthorizationResult(status: status, isAuthorized: true, result: nil)
			}
		#elseif os(macOS)
			if status == .authorizedAlways {
				return AuthorizationResult(status: status, isAuthorized: true, result: nil)
			}
		#else
			if status == .authorizedAlways || status == .authorizedWhenInUse {
				return AuthorizationResult(status: status, isAuthorized: true, result: nil)
			}
		#endif

		if status == .notDetermined {
			return AuthorizationResult(status: status, isAuthorized: false, result: nil)
		}

		return AuthorizationResult(
			status: status,
			isAuthorized: false,
			result: createErrorOutput(error: LocationError.authorizationDenied)
		)
	}
}

// MARK: - Helpers and Delegates

@MainActor
final class CurrentLocationFetcher: NSObject, @MainActor CLLocationManagerDelegate {
	private var continuation: CheckedContinuation<CLLocation, Error>?
	private var timeoutTask: Task<Void, Never>?

	@MainActor
	func requestLocation(using manager: CLLocationManager,
	                     timeout: TimeInterval = 8) async throws -> CLLocation
	{
		if continuation != nil {
			throw LocationError.operationInProgress
		}

		return try await withCheckedThrowingContinuation { continuation in
			self.continuation = continuation
			manager.delegate = self

			#if os(macOS)
				manager.startUpdatingLocation()
			#else
				manager.requestLocation()
			#endif

			timeoutTask = Task { [weak self, weak manager] in
				do {
					try await Task.sleep(nanoseconds: UInt64(timeout * 1_000_000_000))
					guard let self, let manager else { return }
					handleTimeout(manager: manager)
				} catch {
					// cancelled
				}
			}
		}
	}

	@MainActor
	func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
		guard let location = locations.last else { return }
		if let continuation = cleanup(manager: manager) {
			continuation.resume(returning: location)
		}
	}

	@MainActor
	func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
		if let continuation = cleanup(manager: manager) {
			continuation.resume(throwing: error)
		}
	}

	@MainActor
	private func handleTimeout(manager: CLLocationManager) {
		guard let continuation = cleanup(manager: manager) else { return }
		continuation.resume(throwing: LocationError.locationTimeout)
	}

	@MainActor
	private func cleanup(manager: CLLocationManager)
		-> CheckedContinuation<CLLocation, Error>?
	{
		timeoutTask?.cancel()
		timeoutTask = nil
		#if os(macOS)
			manager.stopUpdatingLocation()
		#endif
		manager.delegate = nil
		let continuation = continuation
		self.continuation = nil
		return continuation
	}
}

final class PermissionRequester: NSObject, CLLocationManagerDelegate {
	private let authorizationUpdated = AsyncStream<Void>.makeStream()

	func waitForAuthorizationResponse() async {
		for await _ in authorizationUpdated.stream {
			break
		}
	}

	nonisolated func locationManagerDidChangeAuthorization(_: CLLocationManager) {
		let continuation = authorizationUpdated.continuation
		Task { @MainActor in
			continuation.yield()
			continuation.finish()
		}
	}
}
