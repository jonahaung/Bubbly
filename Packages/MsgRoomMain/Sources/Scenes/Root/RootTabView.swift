//
//  RootTabView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 11/1/26.
//

import Database
import Services
import SwiftUI
import XUI
import Core

struct RootTabView: View {

	@Environment(Router.self) private var router

	var body: some View {
		TabView(selection: selection) {
			ForEach(TabPath.allCases) { tabPath in
				Tab(
					tabPath.localizedName,
					systemImage: tabPath.systemName,
					value: tabPath
				) {
					tabDestination(for: tabPath)
						.toolbarVisibility(
							router.currentNavPaths.isNilOrEmpty ? .automatic : .hidden,
							for: .tabBar
						)
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
	@ViewBuilder func tabDestination(for tabPath: TabPath) -> some View {
		switch tabPath {
		case .test:
			MainNavView(tabPath: tabPath) {
				Playground()
			}
		case .inbox:
			MainNavView(tabPath: tabPath) {
				InboxScene()
			}

		case .contacts:
			MainNavView(tabPath: tabPath) {
				ContactsScene()
			}
		case .settings:
			MainNavView(tabPath: tabPath) {
				SettingsScene()
			}
		}
	}
}
