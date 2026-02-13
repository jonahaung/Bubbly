import Core
import FirebaseAuth
import MsgRoomMain
import Services
import SwiftUI
import XUI

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
				.task {
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
	}
}
