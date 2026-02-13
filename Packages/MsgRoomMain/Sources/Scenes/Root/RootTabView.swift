import Core
import Database
import Services
import SwiftUI
import XUI

struct RootTabView: View {
	@Environment(Router.self) private var router

	var body: some View {
		TabView(selection: selection) {
			ForEach(TabPath.allCases, id: \.self) { tabPath in
				Tab(
					tabPath.localizedName,
					systemImage: tabPath.systemName,
					value: tabPath
				) {
					MainNavView(tabPath: tabPath) {
						tabPath.destination()
					}
					.toolbarVisibility(router.toolBarVisibility(), for: .tabBar)
				}
			}
		}
		.sensoryFeedback(.impact(flexibility: .soft, intensity: 1), trigger: router.selectedTab)
		.tabBarMinimizeBehavior(.onScrollDown)
	}
}

private extension RootTabView {
	var selection: Binding<TabPath> {
		.init(get: { router.selectedTab }, set: { router.selectedTab = $0 })
	}
}

public extension TabPath {
	@MainActor
	@ViewBuilder func destination() -> some View {
		switch self {
		case .test:
			Playground()
		case .inbox:
			InboxScene(viewModel: .init())
		case .contacts:
			ContactsScene()
		case .settings:
			SettingsScene()
		}
	}
}
