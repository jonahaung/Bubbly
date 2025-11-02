//
//  MainNavView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 2/11/25.
//

import SwiftUI
import Services
import MsgRoomMain
import XUI

struct MainNavView<Content: View>: View, Equatable, Identifiable {

	@Bindable var navRouter: NavRouter
	let content: () -> Content
    var body: some View {
		NavigationStack(path: $navRouter.navPath) {
			content()
				.navigationTitle(Text(navRouter.id.rawValue.firstLetterCapitalized))
				.navigationDestination(for: NavPath.self) { navPath in
					navigationDestination(for: navPath)
				}
		}
		.background()
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
		}
	}

	var id: TabPath { navRouter.id }
	static func == (lhs: MainNavView<Content>, rhs: MainNavView<Content>) -> Bool {
		lhs.navRouter.id == rhs.navRouter.id
	}
}
