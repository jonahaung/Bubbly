//
//  Group.swift
//  Database
//
//  Created by Aung Ko Min on 20/8/25.
//

import Foundation

public struct Group: Codable, Sendable, Hashable, UIdentifiable {
    public var uid: String
    public var name: String
    public var createdDate: ServerTime
    public var photoURL: String?
    public var members: [String]
    public var createdBy: String
    public var theme: ConversationTheme = .init()
    public var seenMembers: [SeenMember]?

    public init(
        uid: String,
        name: String,
        createdDate: ServerTime,
        photoURL: String?,
        members: [String],
        createdBy: String,
        theme: ConversationTheme,
        seenMembers: [SeenMember]
    ) {
        self.uid = uid
        self.name = name
        self.createdDate = createdDate
        self.photoURL = photoURL
        self.members = members
        self.createdBy = createdBy
        self.theme = theme
        self.seenMembers = seenMembers
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case createdDate
        case photoURL
        case members
        case createdBy
        case theme
        case seenMembers
    }

	public var conversationProperties: ConversationProperties {
		ConversationProperties(uid: uid, theme: theme, seenMembers: seenMembers ?? [])
	}
}
