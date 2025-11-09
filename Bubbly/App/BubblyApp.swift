//
//  BubblyApp.swift
//  Bubbly
//
//  Created by Aung Ko Min on 27/4/25.
//

import FirebaseAuth
import Services
import SwiftUI
import XUI

@main
struct BubblyApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    var body: some Scene {
        WindowGroup {
            GeometryReader { proxy in
                LandingView()
                    .environment(\.screenSize, proxy.size)
                    .environment(appDelegate.router)
                    .environment(appDelegate.authService)
                    .onOpenURL { url in
                        _ = Auth.auth().canHandle(url)
                    }
            }
        }
    }
}
