// © 2026 Aung Ko Min

import BubblyContacts
import Core
import Database
import Inbox
import Services
import Settings
import SwiftUI
import XUI

struct RootTabView: View {
    let coordinator: AppCoordinator
    private var router: Router {
        coordinator.router
    }

    var body: some View {
        TabView(selection: router.tabPathBinding()) {
            ForEach(TabPath.allCases) { tabPath in
                Tab(value: tabPath, role: role(for: tabPath)) {
                    MainNavView(
                        tabPath: tabPath,
                        coordinator: coordinator
                    ) {
                        coordinator.view(for: tabPath)
                            .navigationDestination(
                                for: NavPath.self
                            ) { navPath in
                                coordinator.view(for: navPath)
                            }
                    }
                } label: {
                    Label(tabPath.name, systemImage: tabPath.systemName)
                        .labelStyle(.iconOnly)
                }
            }
        }
        .toastPresentable()
        .fullScreenCover(item: fullScreenCover) { coordinator.view(for: $0) }
        .tabViewSearchActivation(.automatic)
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

extension RootTabView {
    private func role(for tabPath: TabPath) -> TabRole? {
        tabPath == .search ? .search : nil
    }
}

private extension RootTabView {
    var fullScreenCover: Binding<NavPath?> {
        .init(
            get: { router.sheet },
            set: { newValue in
                guard router.sheet != newValue else {
                    return
                }

                router.sheet = newValue
            },
        )
    }
}

public extension AppCoordinator {
    @ViewBuilder func view(for tabPath: TabPath) -> some View {
        switch tabPath {
        case .inbox:
            InboxScene(coordinator: self)
        case .contacts:
            ContactList(coordinator: self)
        case .settings:
            SettingsScene(coordinator: self)
        case .search:
            PlaygroundView()
        }
    }
}
