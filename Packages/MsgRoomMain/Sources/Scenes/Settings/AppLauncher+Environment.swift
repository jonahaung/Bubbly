import SwiftUI

public extension EnvironmentValues {
	@Entry var appLauncher: AppLauncher = {
		preconditionFailure(
			"AppLauncher not injected. Inject an instance via .environment(appLauncher) from a main-actor context (e.g., in your App)."
		)
	}()

	subscript(_: AppLauncher.Type) -> AppLauncher {
		get { appLauncher }
		set { appLauncher = newValue }
	}
}
