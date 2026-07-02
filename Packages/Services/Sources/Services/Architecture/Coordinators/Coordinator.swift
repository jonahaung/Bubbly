// © 2026 Aung Ko Min

import SwiftUI
import XUI

public protocol Coordinator: Sendable {
    var appLauncher: AppLauncher { get }
    var router: Router { get }
    var container: DependencyContainer { get }
}

@MainActor
public struct AppCoordinator: Coordinator {
    
    public let appLauncher: AppLauncher
    public let router: Router
    public let container: DependencyContainer

    public init(appLauncher: AppLauncher, container: DependencyContainer, router: Router) {
        self.appLauncher = appLauncher
        self.container = container
        self.router = router
    }
}
