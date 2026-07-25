//  ContactListClient.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Database
import Services

struct ContactListContent: Sendable {
    let chatContacts: [Contact]
    let phoneContacts: [Contact]
    let groups: [Group]

    static let empty: ContactListContent = .init(
        chatContacts: [],
        phoneContacts: [],
        groups: []
    )
}

struct ContactListClient: Sendable {
    let load: @Sendable () async throws -> ContactListContent
    let syncContacts: @Sendable () async throws -> Void
    let syncGroups: @Sendable () async throws -> Void
}

extension ContactListClient {
    static let live: ContactListClient = .init(
        load: {
            let contactStore = await Store.shared.contactStore
            let groupStore = await Store.shared.groupStore
            let chatContacts = try await contactStore?.fetchAll() ?? []
            let phoneContacts = try await PhoneContactsService.shared.fetchContacts()
            let groups = try await groupStore?.fetchAll() ?? []
            return ContactListContent(
                chatContacts: chatContacts,
                phoneContacts: phoneContacts,
                groups: groups.sorted {
                    $0.name.localizedStandardCompare($1.name) == .orderedAscending
                }
            )
        },
        syncContacts: {
            try await PhoneContactsService.shared.syncContacts()
        },
        syncGroups: {
            let groups = try await GroupRepo.sync()
            let memberIDs = groups.flatMap(\.members).removeDuplicates()
            try await ContactRepo.getOrCreate(for: memberIDs, refatch: false)
        }
    )
}
