//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import FirebaseAuth
import MsgRoomMain
import Services
import SwiftUI
import XUI
import BackgroundTasks

@main
struct BubblyApp: App {

    private let pushNotificationServie: PushNotificationService
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate
    @Environment(\.scenePhase) private var scenePhase

    init() {
        pushNotificationServie = .init()
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
				.tint(Color.accent)
                .task {
                    await Task.yield()
                    do {
                        try await pushNotificationServie.registerForPushNotifications()
                    } catch {
                        log(error)
                    }
                }
                .task(id: scenePhase) {
                    switch scenePhase {
                    case .background:
                        AppStateStore.set(.background)
						scheduleAppRefresh()
                    case .inactive:
                        AppStateStore.set(.inactive)
                    case .active:
                        AppStateStore.set(.active)
                        do {
                            try await pushNotificationServie.applicationDidBecomeActive()
                        } catch {
                            log(error)
                        }
                    @unknown default:
                        AppStateStore.set(.unknown)
                    }
                }
        }
		.defaultAppStorage(.init(suiteName: AppInformation.groupID) ?? .standard)
		.backgroundTask(.appRefresh(AppInformation.appID)) {
			do {
				try await PhoneContactsService.shared.syncContacts()
				await LocalNotificationService.sendAlert(title: "Contact Sync Complete")
			} catch {
				log(error)
			}
		}
    }

	func scheduleAppRefresh() {
		let request = BGAppRefreshTaskRequest(identifier: AppInformation.appID)
		try? BGTaskScheduler.shared.submit(request)
		log(request)
	}

}
