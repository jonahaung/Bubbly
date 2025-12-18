//
//  AppLauncher+Environment.swift
//  Services
//
//  Created by Aung Ko Min on 16/5/25.
//

import SwiftUI

public extension EnvironmentValues {
    var appLauncher: AppLauncher {
        get { self[AppLauncherKey.self] }
        set { self[AppLauncherKey.self] = newValue }
    }

    subscript(_ type: AppLauncher.Type) -> AppLauncher {
        get { appLauncher }
        set { appLauncher = newValue }
    }
}

private struct AppLauncherKey: EnvironmentKey {
    static let defaultValue: AppLauncher = {
        preconditionFailure("AppLauncher not injected. Inject an instance via .environment(appLauncher) from a main-actor context (e.g., in your App).")
    }()
}
