//
//  BubblyApp.swift
//  Bubbly
//
//  Created by Aung Ko Min on 27/4/25.
//

import FirebaseAuth
import Services
import SwiftUI
import XUI
import MsgRoomMain

@main
struct BubblyApp: App {

	@UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
	private let appLauncher = AppLauncher()
	@Environment(\.scenePhase) var scenePhase

	var body: some Scene {
		WindowGroup {
			AppLaunchingView()
				.environment(appLauncher)
				.task(id: scenePhase) {
					switch scenePhase {
					case .background:
						debugPrint("Background")
					case .inactive:
						debugPrint("Inactive")
					case .active:
						debugPrint("Active")
						appDelegate.pushNotificationService.removeAllNotifications()
					@unknown default:
						debugPrint("scenePhase: @unknown default for ")
					}
				}
				.task {
					appLauncher.startEvaluate()
				}
		}
	}
}
