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
    public var lastPage: LastPage?

    public init(uid: String, theme: ConversationTheme, seenMembers: [SeenMember], lastPage: LastPage?) {
        self.uid = uid
        self.theme = theme
        self.seenMembers = seenMembers
        self.lastPage = lastPage
    }

    public init(uid: String) {
        self.init(uid: uid, theme: .default, seenMembers: [], lastPage: nil)
    }
}
