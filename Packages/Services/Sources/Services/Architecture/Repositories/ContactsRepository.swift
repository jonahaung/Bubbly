// © 2026 Aung Ko Min

import Core
import Database
import FirebaseAuth
import Foundation
import SwiftData
import XUI

// MARK: - ContactsRepository

public final class ContactsRepository: ContactsRepositoryProtocol, @unchecked Sendable, ErrorPresenter {

    private init() {}

    public var contacts: [Contact] = []
    public var groups: [Group] = []

    public func delete(uid: String) async throws {
        if let indext = await contacts.firstIndex(where: { $0.uid == uid }) {
            try await Store.shared
                .contactStore?
                .delete(uid: uid)

            Task { @MainActor in
                contacts.remove(at: indext)
            }
        }
    }

    public func contact(for uid: String) -> Contact? {
        contacts.first(where: { $0.uid == uid })
    }

    public func fetchData() async throws {
        let contacts = try await Store.shared.contactStore?.fetchAll() ?? []
        let groups = try await Store.shared.groupStore?.fetchAll() ?? []
        Task { @MainActor in
            self.contacts = contacts
            self.groups = groups
        }
    }

    public func refresh() async throws {
        try await fetchData()
    }
}

public extension ContactsRepository {
    @concurrent func syncGroups(currentUserId _: String) async throws {
        let groups = try await GroupRepo.sync()
        let memberIDs = groups.flatMap(\.members).removeDuplicates()
        try await ContactRepo.getOrCreate(for: memberIDs, refatch: false)
        try await fetchData()
    }

    @concurrent func syncContacts() async throws {
        try await PhoneContactsService.shared.syncContacts()
        try await fetchData()
    }
}
