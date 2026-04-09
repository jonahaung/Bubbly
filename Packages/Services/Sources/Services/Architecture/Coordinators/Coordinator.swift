//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import SwiftUI
import XUI

public protocol Coordinator: Sendable {
    var appLauncher: AppLauncher { get }
    var router: Router { get }
    var container: DependencyContainer { get }
	func start() async
	func handleDeeplink(_ url: URL) async
}

@MainActor
public struct AppCoordinator: Coordinator {

    public let appLauncher: AppLauncher
    public let router: Router
    public let container: DependencyContainer
    public let deeplinkCoordinator: DeepLinkCoordinator

    public init(appLauncher: AppLauncher, container: DependencyContainer, router: Router) {
        self.appLauncher = appLauncher
        self.container = container
        self.router = .shared
		deeplinkCoordinator = .init(router: router)
    }

    public func handleDeeplink(_ url: URL) async {
        await deeplinkCoordinator.onOpenURL(url: url)
    }

	public func start() async {
		try? await container.contactsRepository.fetchData()
    }
}
