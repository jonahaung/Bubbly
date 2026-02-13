import SwiftUI

public struct ContentView: View {
	@Environment(AppLauncher.self) private var launcher

	public init() {}

	public var body: some View {
		switch launcher.route {
		case .loading:
			LaunchScreen()
				.transition(.opacity)
		case .getStarted:
			AuthFlow()
		case let .main(currentUser):
			RootView()
				.transition(.invisible)
				.msgRoomEntryPoint(currentUser)
		}
	}
}
