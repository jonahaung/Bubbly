//  ConversationProperties.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Core
import Foundation

public struct ConversationProperties: Codable, Sendable, Hashable, Equatable, UIdentifiable {
    public let uid: String
    public var theme: ConversationTheme
    public var seenMembers: [SeenMember]

    public init(uid: String, theme: ConversationTheme, seenMembers: [SeenMember]) {
        self.uid = uid
        self.theme = theme
        self.seenMembers = seenMembers
    }

    public init(uid: String) {
        self.init(uid: uid, theme: .default, seenMembers: [])
    }
}
