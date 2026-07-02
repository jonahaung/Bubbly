// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ArchitecturalView: View {
    
    private let coordinator: AppCoordinator

    init(launcher: AppLauncher, currentUser: CurrentUserModel, router: Router) {
        let currentUserRepository = CurrentUserRepository(currentUser)
        let container = AppDependencyContainer(
            currentUserRepository: currentUserRepository
        )
        coordinator = AppCoordinator(appLauncher: launcher, container: container, router: router)
    }

    public var body: some View {
        RootTabView(coordinator: coordinator)
    }
}
