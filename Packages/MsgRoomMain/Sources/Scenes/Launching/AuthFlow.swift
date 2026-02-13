import Database
import FirePhoneOTP
import Services
import SwiftUI

public struct AuthFlow: View {
	@State private var router = AuthRouter()
	let appLauncher: AppLauncher

	public init(appLauncher: AppLauncher) {
		self.appLauncher = appLauncher
	}

	public var body: some View {
		NavigationStack(path: $router.paths) {
			GetStartedView(appLauncher: appLauncher)
				.navigationDestination(for: AuthRouter.Route.self) { value in
					switch value {
					case .signIn:
						FirePhoneOTPLoginView()
					case let .userInfo(user):
						AuthUserProfileView(user: user, appLauncher: appLauncher)
					case .landing:
						LaunchScreen(appLauncher: appLauncher)
					}
				}
		}
		.environment(router)
		.statusBarHidden()
	}
}
