//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import BackgroundTasks
import Core
import FirebaseAuth
import MsgRoomMain
import Services
import SwiftUI
import XUI
import FirebaseCore

@main
struct BubblyApp: App {
    
	var body: some Scene {
		WindowGroup {
			ContentView()
                .symbolColorRenderingMode(.gradient)
                .allowsTightening(false)
                .tint(Color.accent)
				.onTask {
					await Task.yield()
					do {
						try await appDelegate.pushNotificationServie?.registerForPushNotifications()
					} catch {
						log(error)
					}
				}
				.task(id: scenePhase) {
					switch scenePhase {
					case .background:
						AppStateStore.set(.background)
						appDelegate.backgroundTaskHandler.scheduleAppRefresh()
					case .inactive:
						AppStateStore.set(.inactive)
					case .active:
						AppStateStore.set(.active)
						do {
							try await appDelegate.pushNotificationServie?.applicationDidBecomeActive()
						} catch {
							log(error)
						}
					@unknown default:
						AppStateStore.set(.unknown)
					}
				}
		}
		.defaultAppStorage(.init(suiteName: AppInformation.groupID) ?? .standard)
		.backgroundTask(.appRefresh(AppInformation.BackgroundTask.appRefresh)) { _ in
			await appDelegate.backgroundTaskHandler.handleAppRefresh()
		}
	}

	

	@Environment(\.scenePhase) private var scenePhase
	@UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
}
