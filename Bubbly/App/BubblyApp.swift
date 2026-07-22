//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import BackgroundTasks
import Core
import MsgRoomMain
import SwiftUI

@main
struct BubblyApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            ContentView(
                appLauncher: appDelegate.runtime.appLauncher,
                router: appDelegate.runtime.router
            )
//            .tint(Color.accent)
//            .allowsTightening(true)
            .onOpenURL { url in
                appDelegate.runtime.openURL(url)
            }
            .onTask {
                try? await appDelegate.runtime.registerForPushNotificationsIfNeeded()
                await appDelegate.runtime.startAppLauncher()
            }
        }
        .defaultAppStorage(
            .init(suiteName: AppInformation.groupID) ?? .standard
        )
        .backgroundTask(.appRefresh(AppInformation.BackgroundTask.appRefresh)) {
            _ in
            await appDelegate.runtime.handleAppRefresh()
        }
    }
}
