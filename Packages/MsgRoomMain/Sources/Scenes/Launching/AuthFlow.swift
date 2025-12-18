//
//  AuthFlow.swift
//  Bubbly
//
//  Created by Aung Ko Min on 19/11/25.
//

import Database
import FirePhoneOTP
import SwiftUI

public struct AuthFlow: View {

	@State private var router = AuthRouter()

	public init() {}

	public var body: some View {
		NavigationStack(path: $router.paths) {
			GetStartedView()
				.navigationDestination(for: AuthRouter.Route.self) { value in
					switch value {
					case .signIn:
						FirePhoneOTPLoginView()
					case .userInfo(let user):
						AuthUserProfileView(user: user)
					case .landing:
						LaunchScreen()
					}
				}
		}
		.environment(router)
		.statusBarHidden()
	}
}
