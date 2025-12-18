//
//  MainTabView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Database
import Services
import SwiftUI
import XUI

@MainActor
struct MainTabView: View {

	@Environment(Router.self) private var router

	var body: some View {
		TabView(selection: selection) {
			ForEach(router.navRouters) { navRouter in
				Tab(
					navRouter.id.localizedName,
					systemImage: navRouter.id.systemName,
					value: navRouter.id
				) {
					tabDestination(for: navRouter)
				}
			}
		}
		.sheet(item: sheet) { item in
			NavigationStack {
				item.destination()
			}
		}
		.fullScreenCover(item: fullScreen) { item in
			NavigationStack {
				item.destination()
			}
		}
		.toastPresentable()
	}

	private var selection: Binding<TabPath> {
		.init(get: { router.tab }, set: { router.tab = $0 })
	}

	private var sheet: Binding<NavPath?> {
		.init(get: { router.sheet }, set: { router.sheet = $0 })
	}

	private var fullScreen: Binding<NavPath?> {
		.init(get: { router.fullScreen }, set: { router.fullScreen = $0 })
	}

	private let test = MarkdownView.ContentView()
	private let inbox = InboxScene()
	private let contact = ContactsScene()
	private let settings = SettingsScene()

	@ViewBuilder private func tabDestination(for navRouter: NavRouter) -> some View {
		switch navRouter.id {
			case .test:
				MainNavView(navRouter: navRouter) {
					test
				}
			case .inbox:
				MainNavView(navRouter: navRouter) {
					inbox
				}
			case .contacts:
				MainNavView(navRouter: navRouter) {
					contact
				}
			case .settings:
				MainNavView(navRouter: navRouter) {
					settings
				}
		}
	}
}

public extension NavPath {
	@MainActor @ViewBuilder func destination() -> some View {
		switch self {
			case let .conversationDetails(conversation):
				switch conversation.kind {
					case let .contact(contact):
						ContactSettingsScene(contact)
					case let .group(group):
						GroupConversationSettingsScene(group)
					case let .system(ai):
						ContactSettingsScene(ai)
				}
			case let .conversation(prefetchedData):
				ConversationScene(prefetchedData)
					.navigationTitle("")
					.toolbarVisibility(
						.hidden,
						for: .navigationBar,
						.tabBar,
						.automatic,
						.bottomBar
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
