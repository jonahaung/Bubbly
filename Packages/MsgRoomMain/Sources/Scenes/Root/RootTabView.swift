import Core
import Database
import Inbox
import Services
import SwiftUI
import XUI

struct RootTabView: View {
	let coordinator: AppCoordinator

	var body: some View {
		TabView(selection: coordinator.router.tabPathBinding()) {
			ForEach(TabPath.allCases) { tabPath in
				Tab(value: tabPath, role: role(for: tabPath)) {
					MainNavView(tabPath: tabPath, coordinator: coordinator) {
						coordinator.view(for: tabPath)
					}
					.equatable(by: tabPath == coordinator.router.selectedTab)
					.toolbarVisibility(coordinator.router.toolBarVisibility(), for: .tabBar)
				} label: {
					Image(systemName: tabPath.systemName)
				}
			}
		}
		.symbolRenderingMode(.multicolor)
		.equatable(by: coordinator.router.selectedTab)
		.tabBarMinimizeBehavior(.onScrollDown)
		.toastPresentable()
		.loadingPresentable()
		.sheet(item: sheet) { coordinator.view(for: $0) }
		.onOpenURL { coordinator.handleDeeplink($0) }
	}
}

private extension RootTabView {
	func role(for tabPath: TabPath) -> TabRole? {
		tabPath == .test ? .search : nil
	}
}

private extension RootTabView {
	var sheet: Binding<NavPath?> {
		.init(
			get: { coordinator.router.sheet },
			set: { newValue in
				if let newValue {
					coordinator.router.presnetModel(newValue)
				} else {
					coordinator.router.dismissModal()
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
			InboxScene(viewModel: .init(currentUserRepository: container.currentUserRepository))
		case .contacts:
			ContactsScene(
				router: router, contactsRepository: container.contactsRepository,
				currentUserRepository: container.currentUserRepository
			)
		case .settings:
			SettingsScene(
				currentUserRepository: container.currentUserRepository,
				appLauncher: appLauncher
			)
		}
	}
}
