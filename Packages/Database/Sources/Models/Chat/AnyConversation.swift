//
//  AnyConversation.swift
//  Database
//
//  Created by Aung Ko Min on 24/10/25.
//

//
//  AnyConversation.swift
//  Database
//
//  Created by Aung Ko Min on 24/10/25.
//

import Core
import Foundation

public struct AnyConversation: ConversationRepresentable {
    public var kind: ConversationKind
    public let uid: String
    public var name: String
    public var photoURL: String
    public var members: [String]
    public var theme: ConversationTheme
    public var lastMsgID: String?
    public var seenMembers: [SeenMember]
}

public extension AnyConversation {
    static func createConversationID(for one: String, two: String) -> String {
        one > two ? "\(two)|\(one)" : "\(one)|\(two)"
    }

    init(_ kind: ConversationKind) {
        guard let currentUserID = GroupStorage.shared.string(for: .auth(.currentUserID)) else {
            preconditionFailure("Missing currentUserID in GroupAppStorage")
        }
        self.kind = kind
        switch kind {
        case let .contact(contact):
            uid = Self.createConversationID(for: currentUserID, two: contact.uid)
            name = contact.name
            photoURL = contact.photoURL
            theme = contact.theme ?? .default
            members = [contact.uid]
            lastMsgID = contact.lastMsgID
            seenMembers = contact.seenMember.map { [$0] } ?? []
        case let .group(group):
            uid = group.uid
            name = group.name
            photoURL = group.photoURL ?? ""
            theme = group.theme
            members = group.members
            lastMsgID = group.lastMsgID
            seenMembers = group.seenMembers ?? []
        case let .system(contact):
            uid = Self.createConversationID(for: currentUserID, two: contact.uid)
            name = contact.name
            photoURL = contact.photoURL
            theme = contact.theme ?? .default
            members = [contact.uid]
            lastMsgID = contact.lastMsgID
            seenMembers = contact.seenMember.map { [$0] } ?? []
        }
    }
}
