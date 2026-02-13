import Services
import SwiftUI
import XUI

public struct ContentView: View {
	@LazyState private var appLauncher: AppLauncher

	public init() {
		_appLauncher = .init(wrappedValue: .init())
	}

	public var body: some View {
		switch appLauncher.route {
		case .loading:
			LaunchScreen(appLauncher: appLauncher)
		case .getStarted:
			AuthFlow(appLauncher: appLauncher)
		case let .main(currentUser):
			ArchitecturalView(launcher: appLauncher, currentUser: currentUser)
		}
	}
}
