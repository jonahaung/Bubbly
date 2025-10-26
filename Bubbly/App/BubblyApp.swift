//
//  BubblyApp.swift
//  Bubbly
//
//  Created by Aung Ko Min on 27/4/25.
//

import SwiftUI
import Services
import FirebaseAuth
import SwiftData

@main
struct BubblyApp: App {

	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate

	var body: some Scene {
		WindowGroup {
			LandingView()
				.environment(appDelegate.authService)
				.onOpenURL { url in
					// Forward to Firebase Auth if it can handle the URL (e.g., OAuth, phone auth, etc.)
					_ = Auth.auth().canHandle(url)
					// If you need additional app-specific URL handling, do it here.
				}
		}
	}
}
