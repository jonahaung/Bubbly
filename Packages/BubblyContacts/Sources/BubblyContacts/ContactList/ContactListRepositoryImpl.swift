import Database
import Services
import XUI

@MainActor
struct ContactListRepositoryImpl: ContactListRepository {
    private let manager: ContactListManager
    private let currentUserRepository: CurrentUserRepository

    init(manager: ContactListManager, currentUserRepository: CurrentUserRepository) {
        self.manager = manager
        self.currentUserRepository = currentUserRepository
    }

    func loadInitial() async throws -> ContactListSnapshot {
        try await reloadLocalData()
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func refresh() async throws -> ContactListSnapshot {
        try await reloadLocalData()
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func syncContacts() async throws -> ContactListSnapshot {
        let contacts = try await PhoneContactsService.shared.syncContacts()
        manager.setContacts(contacts)
        manager.setGroups(try await Store.shared.groupStore?.fetchAll() ?? [])
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func syncGroups() async throws -> ContactListSnapshot {
        let currentUser = await currentUserRepository.model
        let currentUserId = currentUser.uid
        let groups: [Group] = try await FirestoreRepo.getModels(
            for: currentUserId,
            collection: .groups,
            field: .members
        )
        let store = await Store.shared.groupStore
        try await AsyncOrderedStream.mapOrdered(inputs: groups) { group in
            try await store?.insert(group)
        }
        let ids = groups.flatMap(\.members).removeDuplicates()
        try await AsyncOrderedStream.mapOrdered(inputs: ids) { uid in
            try await ContactRepo.getOrCreate(uid: uid, refetch: false)
        }
        try await reloadLocalData()
        manager.setLoading(false)
        manager.setError(nil)
        return snapshot()
    }

    func latestSnapshot() async -> ContactListSnapshot {
        snapshot()
    }

    private func snapshot() -> ContactListSnapshot {
        .init(
            contacts: manager.contacts,
            phoneContacts: manager.phoneContacts,
            groups: manager.groups,
            isLoading: manager.isLoading,
            error: manager.error
        )
    }

    private func reloadLocalData() async throws {
        manager.setContacts(try await Store.shared.contactStore?.fetchAll() ?? [])
        manager.setGroups(try await Store.shared.groupStore?.fetchAll() ?? [])
        manager.setPhoneContacts(try await PhoneContactsService.shared.fetchContacts())
    }
}
