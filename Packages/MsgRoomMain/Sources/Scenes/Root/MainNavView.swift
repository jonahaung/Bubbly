//
//  MainNavView.swift
//  Bubbly
//
//  Created by Aung Ko Min on 2/11/25.
//

import Services
import SwiftUI
import XUI

@MainActor
struct MainNavView<Content: View>: View {

	let tabPath: TabPath
	@Environment(Router.self) private var router
	@ViewBuilder var content: () -> Content

	var body: some View {
		NavigationStack(path: router.navPathsBinding(for: tabPath) as Binding<[NavPath]>) {
			content()
				.navigationDestination(for: NavPath.self) { navPath in
					navPath.destination()
				}
		}
	} 
}
