//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import BubblyContacts
import Conversation
import Database
import Services
import Settings
import SwiftUI
import XUI

struct MainNavView<Content: View>: View {
	let tabPath: TabPath
	let coordinator: AppCoordinator
	let content: () -> Content

	var body: some View {
		NavigationStack(
			path: coordinator.router.navPathsBinding(for: tabPath),
		) {
			content()
		}
	}
}

extension AppCoordinator {
	@MainActor @ViewBuilder public func view(for navPath: NavPath) -> some View {
		switch navPath {
		case .conversationDetails(let conversation):
			switch conversation.kind {
			case .contact(let contact):
				ContactProfile(contact, coordinator: self)
			case .group(let group):
				GroupConversationSettingsScene(group, coordinator: self)
			}
		case .conversation(let prefetchedData):
			ConversationScene(coordinator: self, prefretchData: prefetchedData)
				.toolbarVisibility(.hidden, for: .navigationBar, .tabBar)
		case .contactDetails(let contact):
			ContactDetailsScene(contact: contact, coordinator: self)
		case .currentUserDetails:
			UserProfileView(coordinator: self)
		case .view(let node):
			node.eraseToNode()
		}
	}
}
