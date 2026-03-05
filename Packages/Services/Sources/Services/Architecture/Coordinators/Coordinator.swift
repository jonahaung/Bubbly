//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import SwiftUI
import XUI

@MainActor
public protocol Coordinator {
    var appLauncher: AppLauncher { get }
    var router: Router { get }
    var container: DependencyContainer { get }
}

public final class AppCoordinator: @MainActor Coordinator {
    public let appLauncher: AppLauncher
    public let router: Router
    public let container: DependencyContainer
    public let deeplinkCoordinator: DeepLinkCoordinator

    public init(appLauncher: AppLauncher, container: DependencyContainer, router: Router) {
        self.appLauncher = appLauncher
        self.container = container
        self.router = .shared
        deeplinkCoordinator = .init(
            router: router,
            codec: .standard,
            planner: .default(),
            sideEffects: .default
        )
    }

    public func handleDeeplink(_ url: URL) async {
        await deeplinkCoordinator.onOpenURL(url: url)
    }

    public func start() {
        Task.detached(priority: .background) { [weak self] in
            try await self?.container.contactsRepository.fetchData()
        }
    }
}
