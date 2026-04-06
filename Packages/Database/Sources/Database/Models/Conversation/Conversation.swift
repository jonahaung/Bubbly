//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Foundation
import XUI

public struct Conversation: Codable, Sendable, Hashable, Equatable, UIdentifiable {
	
    public let kind: ConversationKind
    public let uid: String
    public let name: String
    public let photoURL: String
    public let members: [String]

    public init(kind: ConversationKind, uid: String) {
        self.kind = kind
        self.uid = uid
        switch kind {
        case let .contact(contact):
            name = contact.name
            photoURL = contact.photoURL
            members = [contact.uid]
        case let .group(group):
            name = group.name
            photoURL = group.photoURL ?? ""
            members = group.members
        }
    }
}

extension Conversation: EmptyRepresentable {
    public static let empty: Conversation = .init(.contact(.empty))
}

public extension Conversation {

    init(_ kind: ConversationKind) {
        guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
            preconditionFailure("Missing currentUserID in GroupAppStorage")
        }
        switch kind {
        case let .contact(contact):
            let uid = ConversationIDGenerator.generate(currentUserID, contact.uid)
            self.init(
                kind: kind,
                uid: uid
            )
        case let .group(group):
            let uid = group.uid
            self.init(
                kind: kind,
                uid: uid
            )
        }
    }

    @concurrent
    func reload(refetch: Bool = false) async throws -> Self {
        try await ConversationRepo
            .getOrCreate(for: uid, refetch: refetch)
    }

    @concurrent
    func saveChanges() async throws {
        switch kind {
        case let .contact(contact):
            try await Store.shared.contactStore?.updateAndSave(uid: contact.uid) { value in
                value.update(from: contact)
            }
        case let .group(group):
            try await Store.shared.groupStore?.updateAndSave(uid: group.uid) { value in
                value.update(from: group)
            }
        }
    }
}

enum ConversationError: Error {
    case invalidType
}
