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
		TabView(selection: selection) {
			ForEach(router.navRouters) { navRouter in
				Tab(
					navRouter.id.localizedName,
					systemImage: navRouter.id.systemName,
					value: navRouter.id
				) {
					tabDestination(for: navRouter)®
				}
			}
		}
		.sheet(item: sheet) { item in
			item.destination()
		}
		.fullScreenCover(item: fullScreen) { item in
			item.destination()
		}
		.toastPresentable()
		.equatable(by: router.tab)
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
	private let test = TestingView()
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
	@ViewBuilder func destination() -> some View {
		switch self {
		case .conversationDetails(let conversation):
			switch conversation.kind {
			case .contact(let contact):
				ContactSettingsScene(contact)
			case .group(let group):
				GroupConversationSettingsScene(group)
			case .system(let ai):
				ContactSettingsScene(ai)
			}
		case .conversation(let prefetchedData):
			ConversationScene(prefetchedData)
				.toolbarVisibility(.hidden, for: .navigationBar, .tabBar)
		case .contactDetails(let contact):
			ContactDetailsScene(contact: contact)
		case .currentUserDetails:
			CurrentUserProfileView()
		}
	}
}
