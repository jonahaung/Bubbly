//  Group.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Foundation

public struct Group: Codable, Sendable, Hashable, UIdentifiable {
    public var uid: String
    public var name: String
    public var createdDate: Date
    public var photoURL: String?
    public var members: [String]
    public var createdBy: String

    public init(
        uid: String,
        name: String,
        createdDate: Date,
        photoURL: String?,
        members: [String],
        createdBy: String
    ) {
        self.uid = uid
        self.name = name
        self.createdDate = createdDate
        self.photoURL = photoURL
        self.members = members
        self.createdBy = createdBy
    }

    enum CodingKeys: String, CodingKey {
        case uid
        case name
        case createdDate
        case photoURL
        case members
        case createdBy
    }

    public func conversationProperties() async -> ConversationProperties {
        await ConversationPropertiesRepo.getOrCreateMain(for: uid)
    }
}
