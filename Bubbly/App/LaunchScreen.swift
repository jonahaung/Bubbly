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

struct LaunchScreen: View {

	@Environment(AuthService.self) private var authService
	@State private var deviceToken: String?
	private let cancelBag = CancelBag()

	var body: some View {
		ZStack {
			VStack {
				if deviceToken != nil {
					SystemImage(.sparkle, 40)
						.transition(.scale.animation(.default))
						.onAppear {
							authService.observeAuthState()
						}
				} else {
					ProgressView().controlSize(.small)
						.onAppear {
							observeDeviceToken()
						}
				}
			}
		}
	}

	private func observeDeviceToken() {
		deviceToken = "Nil"
		NotificationCenter.default.publisher(for: .receiveDeviceToken)
			.receive(on: RunLoop.main)
			.sink { notification in
				deviceToken = notification.object as? String
			}
			.store(in: cancelBag)
	}
}
