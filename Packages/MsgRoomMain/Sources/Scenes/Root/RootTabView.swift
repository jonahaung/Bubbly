import Core
import Database
import Inbox
import Services
import Settings
import SwiftUI
import XUI
import BubblyContacts

struct RootTabView: View {
	let coordinator: AppCoordinator
	private var router: Router { coordinator.router }
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
		.tabBarMinimizeBehavior(.onScrollDown)
		.toastPresentable()
		.fullScreenCover(item: fullScreenCover) { coordinator.view(for: $0) }
		.onOpenURL { url in
			Task.detached {
				await coordinator.handleDeeplink(url)
			}
		}
	}
}

extension RootTabView {
	private func role(for tabPath: TabPath) -> TabRole? {
		tabPath == .settings ? .search : nil
	}
}

extension RootTabView {
	fileprivate var fullScreenCover: Binding<NavPath?> {
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

extension AppCoordinator {
	@ViewBuilder public func view(for tabPath: TabPath) -> some View {
		switch tabPath {
		case .test:
			PlaygroundView()
		case .inbox:
			InboxScene(coordinator: self)
		case .contacts:
			ContactsScene(coordinator: self)
		case .settings:
			SettingsScene(coordinator: self)
		}
	}
}
