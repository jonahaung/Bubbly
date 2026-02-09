//
//  RootNavView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 11/1/26.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct RootNavView: View {
	@Environment(Router.self) private var router

	var body: some View {
		NavigationSplitView {
			SidebarView()
		} detail: {
			tabDestination(for: router.selectedTab)
		}
		.navigationSplitViewStyle(.automatic)
	}

	func tabDestination(for tab: TabPath) -> some View {
		MainNavView(tabPath: tab) {
			switch tab {
			case .test:
				FolderExplorer()
			case .inbox:
				InboxScene()
			case .contacts:
				ContactsScene()
			case .settings:
				SettingsScene()
			}
		}
	}
}

struct SidebarView: View {
	@Environment(Router.self) private var router

	var body: some View {
		List(selection: selection) {
			Section {
				ForEach(TabPath.allCases) { tabPath in
					Button {
						router.selectedTab = tabPath
					} label: {
						Label(tabPath.localizedName, systemImage: tabPath.systemName)
							.symbolRenderingMode(router
								.selectedTab == tabPath ? .multicolor : .hierarchical)
							.symbolVariant(router.selectedTab == tabPath ? .fill : .none)
					}
					.buttonStyle(.borderless)
					.id(tabPath)
				}
			}
		}
		.listStyle(.sidebar)
		.navigationTitle("Bubbley")
	}

	private var selection: Binding<TabPath?> {
		Binding(get: { router.selectedTab }, set: { newValue in
			if let newValue {
				router.selectTab(newValue)
			}
		})
	}
}
