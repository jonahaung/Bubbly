//
//  BubblyApp.swift
//  Bubbly
//
//  Created by Aung Ko Min on 27/4/25.
//

import SwiftUI
import XUI
import Services
import FirebaseAuth

@main
struct BubblyApp: App {
	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	var body: some Scene {
		WindowGroup {
			LandingView()
				.environment(appDelegate.router)
				.environment(appDelegate.authService)
				.onOpenURL { url in
					Log(url)
					_ = Auth.auth().canHandle(url)
				}
		}
	}
}
