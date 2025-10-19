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

	@Bindable var router: Router

	var body: some View {
		@Bindable var router = self.router
		TabView(selection: $router.tab) {
			ForEach($router.navRouters, id: \.id) { navRuter in
				NavigationStack(path: navRuter.navPath) {
					tabDestination(for: navRuter.id)
						.equatable(by: navRuter.id)
						.navigationDestination(for: NavPath.self) { path in
							navigationDestination(for: path)
								.equatable(by: path)
						}
						.environment(router)
				}
				.tabItem {
					Label(navRuter.id.rawValue, systemSymbol: .house)
				}
			}
		}
		.equatable(by: router.tab)
		.toastPresentable()
	}

	@ViewBuilder private func tabDestination(for tabPath: TabPath) -> some View {
		switch tabPath {
		case .test:
			DemoImagesView()
		case .inbox:
			InboxScene()
		case .contacts:
			ContactsScene()
		case .html:
			SettingsScene()
		}
	}
	@ViewBuilder private func navigationDestination(for navPath: NavPath) -> some View {
		switch navPath {
		case .conversationDetails(let conversation):
			if conversation.type == .group {
				GroupConversationSettingsScene(conversation)
			} else {
				SingleConversationSettingsScene(conversation)
			}
		case .conversation(let prefetchedData):
			ConversationScene(prefetchedData)
		case .contactDetails(let contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			CurrentUserProfileView()
		}
	}
}
