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
		TabView(
			selection: .init(get: { router.tab }, set: { router.tab = $0 })
		) {
			ForEach(router.navRouters) { navRuter in
				NavigationStack(
					path: .init(
						get: { navRuter.navPath },
						set: { navRuter.navPath = $0 })
				) {
					tabDestination(for: navRuter.id)
						.navigationDestination(for: NavPath.self) { path in
							navigationDestination(for: path)
						}
				}
				.tabItem {
					Label(navRuter.id.rawValue, systemSymbol: .house)
				}
			}
		}
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
