import Observation

@MainActor
@Observable
final class PlaygroundManager {
	private(set) var isLoading = false
	private(set) var error: String?

	func setLoading(_ value: Bool) {
		isLoading = value
	}

	func setError(_ value: String?) {
		error = value
	}
}
