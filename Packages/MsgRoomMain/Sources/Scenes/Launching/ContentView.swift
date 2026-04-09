//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Services
import SwiftUI
import XUI

public struct ContentView: View {

	// MARK: Lifecycle

	public init() {
		_appLauncher = .init(wrappedValue: .init())
	}

	// MARK: Public

	public var body: some View {
		switch appLauncher.route {
		case .loading:
			LaunchScreen(appLauncher: appLauncher)
		case .getStarted:
			AuthFlow(appLauncher: appLauncher)
		case let .main(currentUser):
			ArchitecturalView(
				launcher: appLauncher,
				currentUser: currentUser,
				router: appLauncher.router
			)
		}
	}

	// MARK: Private

	@LazyState private var appLauncher: AppLauncher
}
