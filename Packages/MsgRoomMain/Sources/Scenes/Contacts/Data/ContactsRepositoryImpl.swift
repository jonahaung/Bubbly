import Database
import Services

@MainActor
struct ContactsRepositoryImpl: ContactsSceneRepository {
	private let manager: ContactsManager
	private let contactsRepository: ContactsRepositoryProtocol
	private let currentUserRepository: CurrentUserRepository

	init(manager: ContactsManager,
	     contactsRepository: ContactsRepositoryProtocol,
	     currentUserRepository: CurrentUserRepository)
	{
		self.manager = manager
		self.contactsRepository = contactsRepository
		self.currentUserRepository = currentUserRepository
	}

	func loadInitial() async throws -> ContactsSnapshot {
		manager.setLoading(true)
		manager.setError(nil)
		try await contactsRepository.fetchData()
		manager.setLoading(false)
		return snapshot()
	}

	func refresh() async throws -> ContactsSnapshot {
		manager.setLoading(true)
		manager.setError(nil)
		try await contactsRepository.refresh()
		manager.setLoading(false)
		return snapshot()
	}

	func syncContacts() async throws -> ContactsSnapshot {
		manager.setLoading(true)
		manager.setError(nil)
		try await contactsRepository.syncContacts()
		manager.setLoading(false)
		return snapshot()
	}

	func syncGroups() async throws -> ContactsSnapshot {
		manager.setLoading(true)
		manager.setError(nil)
		let currentUserId = await currentUserRepository.model.uid
		try await contactsRepository.syncGroups(currentUserId: currentUserId)
		manager.setLoading(false)
		return snapshot()
	}

	func updateSearchText(_ value: String) async -> ContactsSnapshot {
		manager.setSearchText(value)
		return snapshot()
	}

	func latestSnapshot() async -> ContactsSnapshot {
		snapshot()
	}

	private func snapshot() -> ContactsSnapshot {
		ContactsSnapshot(
			isLoading: manager.isLoading,
			error: manager.error,
			searchText: manager.searchText
		)
	}
}
