//  PGroup.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData
import Foundation

// MARK: - PGroup

@Model
public final class PGroup {
    @Attribute(.unique)
    public var uid: String
    public var name: String
    public var createdDate: Date
    public var photoURL: String
    public var members: [String]
    public var createdBy: String
//    public var theme: ConversationTheme

    public init(
        uid: String,
        name: String,
        createdDate: Date,
        photoURL: String,
        members: [String],
        createdBy: String,
        theme _: ConversationTheme = ConversationTheme()
    ) {
        self.uid = uid
        self.name = name
        self.createdDate = createdDate
        self.photoURL = photoURL
        self.members = members
        self.createdBy = createdBy
    }
    
    public required init(from decoder: any Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.name = try container.decode(String.self, forKey: .name)
        self.createdDate = try container.decode(Date.self, forKey: .createdDate)
        self.photoURL = try container.decode(String.self, forKey: .photoURL)
        self.members = try container.decode([String].self, forKey: .members)
        self.createdBy = try container.decode(String.self, forKey: .createdBy)
    }

    public func encode(to encoder: any Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(name, forKey: .name)
        try container.encode(createdDate, forKey: .createdDate)
        try container.encode(photoURL, forKey: .photoURL)
        try container.encode(members, forKey: .members)
        try container.encode(createdBy, forKey: .createdBy)
    }

    private enum CodingKeys: String, CodingKey {
        case uid
        case name
        case createdDate
        case photoURL
        case members
        case createdBy
    }
}

// MARK: UIdentifiable

extension PGroup: UIdentifiable {
    public func update(with conversation: Conversation) {
        if name != conversation.name {
            name = conversation.name
        }
        if photoURL != conversation.photoURL {
            photoURL = conversation.photoURL
        }
        if members.sorted() != conversation.members.sorted() {
            members = conversation.members
        }
    }

    public func update(with _: ConversationProperties) {}

    public func update(from item: Group) {
        if name != item.name {
            name = item.name
        }
        if photoURL != item.photoURL {
            photoURL = item.photoURL ?? ""
        }
        if members.uniqued().sorted() != item.members.uniqued().sorted() {
            members = item.members.uniqued().sorted()
        }
    }
}

// MARK: SendableTransformable

extension PGroup: SendableTransformable {
    public typealias SendableType = Group

    public convenience init(from snapshot: SendableType) {
        self.init(
            uid: snapshot.uid,
            name: snapshot.name,
            createdDate: snapshot.createdDate,
            photoURL: snapshot.photoURL ?? "",
            members: snapshot.members,
            createdBy: snapshot.createdBy
        )
    }

    public func toSendable() -> SendableType {
        SendableType(
            uid: uid,
            name: name,
            createdDate: createdDate,
            photoURL: photoURL,
            members: members,
            createdBy: createdBy
        )
    }
}
