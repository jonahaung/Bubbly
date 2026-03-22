//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Foundation
import XUI

public struct ConversationProperties: Codable, Sendable, Hashable, Equatable, UIdentifiable {
    public let uid: String
    public var theme: ConversationTheme
    public var seenMembers: [SeenMember]

    public init(uid: String, theme: ConversationTheme, seenMembers: [SeenMember]) {
        self.uid = uid
        self.theme = theme
        self.seenMembers = seenMembers
		print(seenMembers)
    }

    public init(uid: String) {
        self.init(uid: uid, theme: .default, seenMembers: [])
    }
}

extension ConversationProperties: EmptyRepresentable {
    public static let empty: ConversationProperties = .init(uid: "")
}
