//
//  MainTabView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import SwiftUI
import Database
import MsgRoomMain
import Services
import XUI

struct MainTabView: View {

	@Environment(Router.self) private var router

	var body: some View {
		@Bindable var bindableRouter = self.router
		TabView(selection: $bindableRouter.tab) {
			ForEach(router.navRouters, id: \.id) { navRouter in
				MainNavView(navRouter: navRouter) {
					tabDestination(for: navRouter.id)
				}
				.tabItem {
					Label(navRouter.id.rawValue, systemSymbol: .house)
				}
			}
		}
		.toastPresentable()
	}

	@ViewBuilder private func tabDestination(for tabPath: TabPath) -> some View {
		switch tabPath {
		case .test:
			FolderExplorer()
		case .inbox:
			InboxScene()
		case .contacts:
			ContactsScene()
		case .html:
			SettingsScene()
		}
	}
}
