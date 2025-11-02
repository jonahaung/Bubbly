//
//  LaunchScreen.swift
//  Bubbly
//
//  Created by Aung Ko Min on 17/8/25.
//

import SwiftUI
import Services
import XUI
import Core
import FirebaseMessaging

struct LaunchScreen: View {

	@Environment(AuthService.self) private var authService
	@State private var tokenObserver: NSObjectProtocol?

	var body: some View {
		ZStack {
			VStack {
				SystemImage(.sparkle, 40)
					.transition(.scale.animation(.default))
				Button("Start") {
					GroupAppStorage.shared.save(value: "", for: .device(.deviceToken))
					NotificationCenter.default.post(name: .receiveDeviceToken, object: "")
				}
			}
			.onAppear(perform: observeDeviceToken)
			.onDisappear(perform: removeDeviceTokenObserver)
		}
	}

	private func observeDeviceToken() {
		tokenObserver = NotificationCenter.default.addObserver(
			forName: .receiveDeviceToken,
			object: nil,
			queue: .main
		) { notification in
			MainActor.assumeIsolated {
				if notification.object is String {
					authService.observeAuthState()
				}
			}
		}
	}

	private func removeDeviceTokenObserver() {
		if let observer = tokenObserver {
			NotificationCenter.default.removeObserver(observer)
			tokenObserver = nil
			Log("🧹 Removed device token observer")
		}
	}
}
