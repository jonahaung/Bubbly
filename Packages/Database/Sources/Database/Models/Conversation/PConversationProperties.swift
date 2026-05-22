//  PConversationProperties.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData

@Model
public final class PConversationProperties: Codable {
    @Attribute(.unique)
    public var uid: String
    public var theme: ConversationTheme
    public var seenMembers: [SeenMember]
    @Attribute(.ephemeral)
    public var lastPage: LastPage?

    private enum CodingKeys: String, CodingKey {
        case uid
        case theme
        case seenMembers
        // Intentionally exclude `lastPage` because it's marked as `.ephemeral`
    }

    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.uid = try container.decode(String.self, forKey: .uid)
        self.theme = try container.decode(ConversationTheme.self, forKey: .theme)
        self.seenMembers = try container.decode([SeenMember].self, forKey: .seenMembers)
        // Do not decode `lastPage` (ephemeral)
        self.lastPage = nil
    }

    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(uid, forKey: .uid)
        try container.encode(theme, forKey: .theme)
        try container.encode(seenMembers, forKey: .seenMembers)
        // Do not encode `lastPage` (ephemeral)
    }

    public init(
        uid: String,
        theme: ConversationTheme,
        seenMembers: [SeenMember],
        lastPage: LastPage?
    ) {
        self.uid = uid
        self.theme = theme
        self.seenMembers = seenMembers
        self.lastPage = lastPage
    }
}

// MARK: SendableTransformable

extension PConversationProperties: SendableTransformable {
    public func update(from item: ConversationProperties) {
        if theme != item.theme {
            theme = item.theme
        }
        if seenMembers != item.seenMembers {
            seenMembers = item.seenMembers
        }
        if lastPage != item.lastPage {
            lastPage = item.lastPage
        }
    }

    public convenience init(from sendable: ConversationProperties) {
        self.init(
            uid: sendable.uid,
            theme: sendable.theme,
            seenMembers: sendable.seenMembers,
            lastPage: sendable.lastPage
        )
    }

    public func toSendable() -> ConversationProperties {
        .init(
            uid: uid,
            theme: theme,
            seenMembers: seenMembers, lastPage: lastPage
        )
    }
}
