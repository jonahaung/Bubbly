import Core
import Database
import Services
import SwiftUI
import XUI

struct RootView: View {
	@Environment(Router.self) private var router

	var body: some View {
		RootTabView()
			.toastPresentable()
			.loadingPresentable()
			.sheet(item: sheet) { item in
				item.destination()
			}
			.onOpenURL { url in
				Task.detached(priority: .background) {
					await DeepLinkCoordinator.shared.onOpenURL(url: url)
				}
			}
	}
}

private extension RootView {
	var sheet: Binding<NavPath?> {
		.init(
			get: { router.sheet },
			set: { newValue in
				if let newValue {
					router.presnetModel(newValue)
				} else {
					router.dismissModal()
				}
			}
		)
	}
}

@MainActor
extension NavPath {
	@ViewBuilder
	public func destination() -> some View {
		switch self {
		case let .conversationDetails(conversation):
			conversationDestination(conversation)
		case let .conversation(prefetchedData):
			ConversationScene(prefetchedData)
		case let .contactDetails(contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			CurrentUserProfileView()
		case let .view(_, node):
			node.eraseToNode()
		}
	}

	@ViewBuilder
	private func conversationDestination(_ conversation: Conversation) -> some View {
		switch conversation.kind {
		case let .contact(contact):
			ContactSettingsScene(contact)
		case let .group(group):
			GroupConversationSettingsScene(group)
		}
	}
}
