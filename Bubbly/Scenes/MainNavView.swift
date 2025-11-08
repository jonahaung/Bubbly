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

	let navRouter: NavRouter
	@ViewBuilder var content: () -> Content

	var body: some View {
		NavigationStack(path: navPath) {
			content()
				.navigationTitle(navRouter.id.localizedName)
				.navigationDestination(for: NavPath.self) { navPath in
					navPath.destination()
						.navigationTitle(navPath.localizedName)
				}
		}
	}
	var id: TabPath { navRouter.id }
	static func == (lhs: MainNavView<Content>, rhs: MainNavView<Content>) -> Bool {
		lhs.id == rhs.id
	}

	private var navPath: Binding<[NavPath]> {
		.init(get: { navRouter.navPath }, set: { navRouter.navPath = $0 })
	}
}
