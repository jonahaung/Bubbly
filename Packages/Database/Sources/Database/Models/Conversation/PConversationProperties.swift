//  PConversationProperties.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import SwiftData

// MARK: - PConversationProperties

@Model
public final class PConversationProperties {
    @Attribute(.unique)
    public var uid: String
    public var theme: ConversationTheme
    public var seenMembers: [SeenMember]

    public init(
        uid: String,
        theme: ConversationTheme,
        seenMembers: [SeenMember]
    ) {
        self.uid = uid
        self.theme = theme
        self.seenMembers = seenMembers
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
    }

    public convenience init(from sendable: ConversationProperties) {
        self.init(
            uid: sendable.uid,
            theme: sendable.theme,
            seenMembers: sendable.seenMembers
        )
    }

    public func toSendable() -> ConversationProperties {
        .init(
            uid: uid,
            theme: theme,
            seenMembers: seenMembers
        )
    }
}
