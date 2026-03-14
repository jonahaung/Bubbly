//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Inbox
import Services
import Settings
import SwiftUI
import XUI

struct RootTabView: View {
    let coordinator: AppCoordinator
	private var router: Router { coordinator.router }
    var body: some View {
        TabView(selection: router.tabPathBinding()) {
            ForEach(TabPath.allCases) { tabPath in
                Tab(value: tabPath, role: role(for: tabPath)) {
                    MainNavView(tabPath: tabPath, coordinator: coordinator) {
                        coordinator.view(for: tabPath)
                    }
                } label: {
                    Image(systemName: tabPath.systemName)
                }
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
        .toastPresentable()
        .loadingPresentable()
        .sheet(item: sheet) { coordinator.view(for: $0) }
        .onOpenURL { url in
            Task {
                await coordinator.handleDeeplink(url)
            }
        }
    }
}

private extension RootTabView {
    func role(for tabPath: TabPath) -> TabRole? {
		tabPath == .contacts ? .search : nil
    }
}

private extension RootTabView {
    var sheet: Binding<NavPath?> {
        .init(
            get: { router.sheet },
            set: { newValue in
                if let newValue {
                    router.presentModel(newValue)
                } else {
                    router.dismissModal()
                }
            }
        )
    }
}

public extension AppCoordinator {
    @ViewBuilder func view(for tabPath: TabPath) -> some View {
        switch tabPath {
        case .test:
            PlaygroundView()
        case .inbox:
			InboxScene(coordinator: self)
        case .contacts:
			ContactsScene(coordinator: self)
        case .settings:
            SettingsScene(
                currentUserRepository: container.currentUserRepository,
                appLauncher: appLauncher
            )
        }
    }
}
