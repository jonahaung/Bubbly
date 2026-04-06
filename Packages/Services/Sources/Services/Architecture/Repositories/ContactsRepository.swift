//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import FirebaseAuth
import Foundation
import SwiftData
import XUI

public final class ContactsRepository: ContactsRepositoryProtocol, Sendable, ErrorPresenter {
    @MainActor
    public static var shared: ContactsRepository {
        get { sharedLock.value }
        set { sharedLock.value = newValue }
    }

    private static let sharedLock = Mutex(ContactsRepository())
    private init() {}

    public var contacts = [Contact]()
    public var groups = [Group]()

    public func delete(uid: String) async throws {
        if let indext = await contacts.firstIndex(where: { $0.uid == uid }) {
            try await Store.shared.contactStore?
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
    @concurrent func syncGroups(currentUserId: String) async throws {
        let groups: [Group] = try await FirestoreRepo.getModels(
            for: currentUserId,
            collection: .groups,
            field: .members
        )
		let store = await Store.shared.groupStore

        try await withThrowingTaskGroup(of: Void.self) { taskGroup in
            for group in groups {
                taskGroup.addTask {
                    if try await store?.exists(uid: group.uid) == false {
                        try await store?.insert(group)
                    } else {
                        try await store?.updateAndSave(uid: group.uid) { model in
                            model.update(from: group)
                        }
                    }
                    try await ContactRepo.getOrCreate(for: group.members, refatch: false)
                }
            }
            try await taskGroup.waitForAll()
        }
        try await fetchData()
    }

    @concurrent func syncContacts() async throws {
        try await PhoneContactsService.shared.syncContacts()
        try await fetchData()
    }
}
