// © 2026 Aung Ko Min

import Core
import Foundation
import SwiftData
import XUI

public enum ConversationRepo {
    public enum XError: Error {
        case noCurrentUserID
        case invalidConversationID
        case savingFailed
        case noConversationGroupFound
    }

    // MARK: - Conversation

    @discardableResult
    public static func getOrCreate(for conID: String, refetch: Bool) async throws -> Conversation {
        let kind = try await getConversationKind(for: conID, refetch: refetch)
        return Conversation(kind)
    }

    public static func getConversationKind(for conID: String,
                                           refetch: Bool) async throws -> ConversationKind
    {
        if conID.contains("|") { // Contact conversation
            let contactID = try resolveContactID(from: conID)
            let contact = try await ContactRepo.getOrCreate(uid: contactID, refetch: refetch)
            return .contact(contact)
        }

        if !refetch,
           let existing: PGroup.SendableType = try await Store.shared
           .groupStore?
           .fetch(uid: conID)
        {
            return .group(existing)
        }

        let group: Database.Group
        do {
            group = try await FirestoreRepo.getDocument(collection: .groups, documentID: conID)
        } catch {
            guard let fetched: Database.Group = try await FirestoreRepo.getModel(
                for: conID,
                collection: .groups,
                field: .uid,
            ) else {
                throw XError.noConversationGroupFound
            }

            group = fetched
        }
        try await Store.shared.groupStore?.insert(group)
        try await ContactRepo.getOrCreate(for: group.members, refatch: refetch)
        return .group(group)
    }

    // MARK: - Helpers

    static func resolveContactID(from conID: String) throws -> String {
        var components = conID.components(separatedBy: "|")
        guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
            throw XError.noCurrentUserID
        }

        components.removeAll { $0 == currentUserID }
        guard let contactID = components.first,
              !contactID.isEmpty else
        {
            throw XError.invalidConversationID
        }

        return contactID
    }

    public static func search(from name: String,
                              currentUserId _: String) async throws -> Conversation?
    {
        if let contact = try await ContactRepo
            .search(named: name)
        {
            return Conversation(.contact(contact))
        }
        if let group = try await ContactRepo
            .searchGroup(named: name)
        {
            return Conversation(.group(group))
        }
        return nil
    }
}
