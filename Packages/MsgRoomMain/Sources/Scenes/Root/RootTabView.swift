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
			ForEach(router.navRouters) { navRouter in
				Tab(
					navRouter.id.localizedName,
					systemImage: navRouter.id.systemName,
					value: navRouter.id
				) {
					MainNavView(navRouter: navRouter) {
						tabDestination(for: navRouter)
							.navigationTitle(navRouter.id.localizedName)
					}
				}
			}
		}
		.ignoresSafeArea()
		.tabBarMinimizeBehavior(.onScrollDown)
	}
}

private extension RootTabView {
	var selection: Binding<TabPath> {
		.init(get: { router.tab }, set: { router.tab = $0 })
	}
	@ViewBuilder func tabDestination(for navRouter: NavRouter) -> some View {
		switch navRouter.id {
		case .test:
			FolderExplorer()
		case .inbox:
			InboxScene()
				.toolbarVisibility(
					router.tabBarVisibility,
					for: .tabBar
				)
		case .contacts:
			ContactsScene()
		case .settings:
			SettingsScene()
		}
	}
}
