// © 2026 Aung Ko Min

import BubblyContacts
import Core
import Database
import Inbox
import Services
import Settings
import SwiftUI
import XUI

// MARK: - RootTabView

struct RootTabView: View {
    let coordinator: AppCoordinator
    private var router: Router {
        coordinator.router
    }

    var body: some View {
        TabView(selection: router.tabPathBinding()) {
            ForEach(TabPath.allCases) { tabPath in
                Tab(value: tabPath, role: role(for: tabPath)) {
                    MainNavView(tabPath: tabPath, coordinator: coordinator) {
                        coordinator.view(for: tabPath)
                            .navigationDestination(for: NavPath.self) { navPath in
                                coordinator.view(for: navPath)
                            }
                    }
                } label: {
                    Label(tabPath.name, systemImage: tabPath.systemName)
                        .labelStyle(.iconOnly)
                }
            }
        }
		.tabViewSearchActivation(.automatic)
		.searchToolbarBehavior(.minimize)
		.searchPresentationToolbarBehavior(.avoidHidingContent)
        .tabBarMinimizeBehavior(.onScrollDown)
        .toastPresentable()
        .fullScreenCover(item: fullScreenCover) { coordinator.view(for: $0) }
    }
}

extension RootTabView {
    private func role(for tabPath: TabPath) -> TabRole? {
		tabPath == .contacts ? .search : nil
    }
}

private extension RootTabView {
    var fullScreenCover: Binding<NavPath?> {
        .init(
            get: { router.sheet },
            set: { newValue in
                if let newValue {
                    router.presentModel(newValue)
                } else {
                    router.dismissModal()
                }
            },
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
			ContactList(coordinator: self)
        case .settings:
            SettingsScene(coordinator: self)
        }
    }
}
