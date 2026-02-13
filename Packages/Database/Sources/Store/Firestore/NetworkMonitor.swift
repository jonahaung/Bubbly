import Foundation
import Network

@MainActor
final class NetworkMonitor {
	private let monitor = NWPathMonitor()

	private(set) var hasNetworkConnection = false
	private(set) var isUsingMobileConnection = false

	init() {
		monitor.pathUpdateHandler = { [weak self] path in
			guard let self else { return }
			Task { @MainActor in
				self.hasNetworkConnection = path.status == .satisfied
				self.isUsingMobileConnection = path.usesInterfaceType(.cellular)
			}
		}
		monitor.start(queue: .global())
	}

	deinit {
		monitor.cancel()
	}
}
