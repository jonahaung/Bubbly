import Core
import Database
import Services
import SwiftUI
import XUI

public struct ArchitecturalView: View {
	private let coordinator: AppCoordinator

	init(launcher: AppLauncher, currentUser: CurrentUserModel) {
		let currentUserRepository = CurrentUserRepository(currentUser)
		let contactsRepository = ContactsRepository.shared

		let container = AppDependencyContainer(
			currentUserRepository: currentUserRepository,
			contactsRepository: contactsRepository
		)
		let router = Router.shared
		coordinator = AppCoordinator(appLauncher: launcher, container: container, router: router)
	}

	public var body: some View {
		RootTabView(coordinator: coordinator)
			.task {
				coordinator.start()
			}
	}
}
