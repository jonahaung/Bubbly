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

    private var navPath: Binding<[NavPath]> {
        .init(get: { navRouter.navPath }, set: { navRouter.navPath = $0 })
    }
}
