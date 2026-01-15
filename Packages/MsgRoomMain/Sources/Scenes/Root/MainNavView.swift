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
	
	@Bindable var navRouter: NavRouter
	@ViewBuilder var content: () -> Content
	
	var body: some View {
		NavigationStack(path: $navRouter.navPath) {
			content()
				.navigationDestination(for: NavPath.self) { navPath in
					navPath.destination()
				}
		}
	}
}
