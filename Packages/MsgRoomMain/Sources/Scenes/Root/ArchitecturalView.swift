//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ArchitecturalView: View {

    private let coordinator: AppCoordinator
	
    init(launcher: AppLauncher, currentUser: CurrentUserModel, router: Router) {
        let currentUserRepository = CurrentUserRepository(currentUser)
        let contactsRepository = ContactsRepository.shared

        let container = AppDependencyContainer(
            currentUserRepository: currentUserRepository,
            contactsRepository: contactsRepository
        )
		coordinator = AppCoordinator(appLauncher: launcher, container: container, router: router)
    }

    public var body: some View {
        RootTabView(coordinator: coordinator)
            .onTask {
				await coordinator.start()
            }
    }
}
