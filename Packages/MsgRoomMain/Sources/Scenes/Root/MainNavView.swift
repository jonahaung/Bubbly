import Conversation
import Database
import Services
import Settings
import SwiftUI
import XUI

struct MainNavView<Content: View>: View {
	let tabPath: TabPath
	let coordinator: AppCoordinator
	@ViewBuilder var content: () -> Content

	var body: some View {
		NavigationStack(
			path: coordinator.router.navPathsBinding(for: tabPath) as Binding<[NavPath]>
		) {
			content()
				.navigationDestination(for: NavPath.self) { navPath in
					coordinator.view(for: navPath)
				}
		}
	}
}

public extension AppCoordinator {
	@ViewBuilder func view(for navPath: NavPath) -> some View {
		switch navPath {
		case let .conversationDetails(conversation):
			switch conversation.kind {
			case let .contact(contact):
				ContactSettingsScene(contact)
			case let .group(group):
				GroupConversationSettingsScene(group)
			}
		case let .conversation(prefetchedData):
			ConversationScene(prefetchedData, coordinator: self)
		case let .contactDetails(contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			UserProfileView(viewModel: .init(currentUserRepository: container
					.currentUserRepository))
		case let .view(_, node):
			node.eraseToNode()
		}
	}
}
