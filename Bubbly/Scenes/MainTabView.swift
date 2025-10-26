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
		TabView(selection: $router.tab) {
			ForEach($router.navRouters, id: \.id) { navRuter in
				NavigationStack(path: navRuter.navPath) {
					tabDestination(for: navRuter.id)
						.equatable(by: navRuter.id)
						.navigationDestination(for: NavPath.self) { path in
							LazyView(navigationDestination(for: path))
								.equatable(by: path)
						}
				}
				.tabItem {
					Label(navRuter.id.rawValue, systemSymbol: .house)
				}
			}
		}
		.environment(router)
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
	@ViewBuilder private func navigationDestination(for navPath: NavPath) -> some View {
		switch navPath {
		case .conversationDetails(let conversation):
			switch conversation.kind {
			case .contact(let contact):
				ContactSettingsScene(contact)
			case .group(let group):
				GroupConversationSettingsScene(group)
			case .system(let ai):
				Text(ai.preetyPrinted)
			}
		case .conversation(let prefetchedData):
			ConversationScene(prefetchedData)
		case .contactDetails(let contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			CurrentUserProfileView()
		case .cachedView(let id):
			AnyViewCache.shared.view(for: id)?.eraseToAnyView()
		}
	}
}
