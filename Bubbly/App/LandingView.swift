//
//  LandingView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 24/5/25.
//

import SwiftUI
import MsgRoomMain
import Services
import FirePhoneOTP
import Database

struct LandingView: View {

	@Environment(AuthService.self) private var authService

	@ViewBuilder
	var body: some View {
		switch authService.authState {
		case .loggedIn(let user):
			MainTabView()
				.msgRoomEntryPoint(user: user)
		case .loggedOut:
			FirePhoneOTPLoginView()
		case .newUser(let user):
			NavigationStack {
				CurrentUserProfileView()
			}
			.environment(CurrentUser(user))
		case .unknown:
			LaunchScreen()
		}
	}
}
