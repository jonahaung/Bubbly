//
//  LandingView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 24/5/25.
//

import Database
import FirePhoneOTP
import MsgRoomMain
import Services
import SwiftUI

struct LandingView: View {
    @Environment(AuthService.self) private var authService

    @ViewBuilder
    var body: some View {
        switch authService.authState {
        case let .loggedIn(user):
            MainTabView()
                .msgRoomEntryPoint(user)
        case .loggedOut:
            FirePhoneOTPLoginView()
        case let .newUser(user):
            NavigationStack {
                CurrentUserProfileView()
            }
            .environment(\.currentUser, .init(user))
            .environment(authService)
        case .unknown:
            ProgressView().controlSize(.mini)
        case .initial:
            LaunchScreen()
        }
    }
}
