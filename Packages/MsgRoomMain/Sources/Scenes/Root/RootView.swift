//
//  RootView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Database
import Services
import SwiftUI
import XUI
import Core

struct RootView: View {

	@Environment(Router.self) private var router
	@Environment(\.horizontalSizeClass) private var horizontalSizeClass

	var body: some View {
		Group {
			if horizontalSizeClass == .compact {
				RootTabView()
			} else {
				RootNavView()
			}
		}
		.toastPresentable()
		.sheet(item: sheet) { item in
			LazyLoadedView {
				NavigationStack {
					item.destination()
						.navigationTitle(item.localizedName)
				}
			}
		}
		.fullScreenCover(item: fullScreen) { item in
			LazyLoadedView {
				NavigationStack {
					item.destination()
						.navigationTitle(item.localizedName)
				}
			}
		}
	}
}

private extension RootView {
	var sheet: Binding<NavPath?> {
		.init(get: { router.sheet }, set: { router.sheet = $0 })
	}
	var fullScreen: Binding<NavPath?> {
		.init(get: { router.fullScreen }, set: { router.fullScreen = $0 })
	}
}

@MainActor
public extension NavPath {
	@ViewBuilder func destination() -> some View {
		switch self {
		case let .conversationDetails(conversation):
			switch conversation.kind {
			case let .contact(contact):
				ContactSettingsScene(contact)
			case let .group(group):
				GroupConversationSettingsScene(group)
			}
		case let .conversation(prefetchedData):
			ConversationScene(prefetchedData)
				.toolbarVisibility(
					.hidden,
					for: .navigationBar, .automatic, .bottomBar
				)
		case let .contactDetails(contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			CurrentUserProfileView()
		case .conversationLazy(let conID):
			ConversationLazyScene(conID)
		}
	}
}
