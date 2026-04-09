// © 2026 Aung Ko Min

import Foundation
import SwiftData

// MARK: - PGroup

@Model
public final class PGroup {
    @Attribute(.unique)
    public var uid: String
    public var name: String
    public var createdDate: String
    public var photoURL: String
    public var members: [String]
    public var createdBy: String
//    public var theme: ConversationTheme

    public init(
        uid: String,
        name: String,
        createdDate: String,
        photoURL: String,
        members: [String],
        createdBy: String,
        theme _: ConversationTheme = ConversationTheme(),
    ) {
        self.uid = uid
        self.name = name
        self.createdDate = createdDate
        self.photoURL = photoURL
        self.members = members
        self.createdBy = createdBy
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
            photoURL = item.photoURL ?? photoURL
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
            createdBy: snapshot.createdBy,
        )
    }

    public func toSendable() -> SendableType {
        SendableType(
            uid: uid,
            name: name,
            createdDate: .init(createdDate),
            photoURL: photoURL,
            members: members,
            createdBy: createdBy,
        )
    }
}
