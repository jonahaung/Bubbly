//
//  RootNavView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 11/1/26.
//

import Database
import Services
import SwiftUI
import XUI
import Core

struct RootNavView: View {

	@Environment(Router.self) private var router
	@State private var columnVisibility: NavigationSplitViewVisibility = .all

	var body: some View {
		NavigationSplitView(columnVisibility: $columnVisibility) {
			SidebarView()
		} detail: {
			tabDestination(for: router.currentNavRouter)
		}
		.navigationSplitViewStyle(.balanced)
	}

	@ViewBuilder func tabDestination(for navRouter: NavRouter) -> some View {
		switch navRouter.id {
		case .test:
			MainNavView(navRouter: navRouter) {
				FolderExplorer()
			}
		case .inbox:
			MainNavView(navRouter: navRouter) {
				InboxScene()
			}
		case .contacts:
			MainNavView(navRouter: navRouter) {
				ContactsScene()
			}
		case .settings:
			MainNavView(navRouter: navRouter) {
				SettingsScene()
			}
		}
	}
}

struct SidebarView: View {

	@Environment(Router.self) private var router

	var body: some View {
		List {
			ForEach(router.navRouters, id: \.id) { navRouter in
				let tabPath = navRouter.id
				Button {
					router.tab = tabPath
				} label: {
					Label(tabPath.localizedName, systemImage: tabPath.systemName)
						.symbolRenderingMode(router.tab == tabPath ? .multicolor : .hierarchical)
						.symbolVariant(router.tab == tabPath ? .fill : .none)
				}
				.buttonStyle(.borderless)
				.id(tabPath)
			}
		}
		.listStyle(.sidebar)
		.navigationTitle("Bubbly")
	}
}
