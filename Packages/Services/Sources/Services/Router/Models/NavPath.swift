//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Foundation
import SwiftUI
import XUI

public enum NavPath: Hashable, @unchecked Sendable, Identifiable, CaseNameReflectable {
    case conversationDetails(_ conversation: Conversation)
    case conversation(_ prefatchData: ConversationInitializer.PrefetchedData)
    case contactDetails(_ contact: Contact)
    case currentUserDetails
    case view(id: AnyHashable, node: RenderNode)

    public var id: String {
        hashValue.description
    }

    public func hash(into hasher: inout Hasher) {
        switch self {
        case let .conversationDetails(snapshot):
            hasher.combine(0)
            hasher.combine(snapshot.uid)
        case let .conversation(data):
            hasher.combine(1)
            hasher.combine(data.conversation.uid)
        case let .contactDetails(snapshot):
            hasher.combine(2)
            hasher.combine(snapshot.uid)
        case .currentUserDetails:
            hasher.combine(3)
        case let .view(id, _):
            hasher.combine(4)
            hasher.combine(id)
        }
    }

    public static func == (lhs: NavPath, rhs: NavPath) -> Bool {
        lhs.id == rhs.id
    }
}

public extension NavPath {
    @MainActor static func view(_ node: RenderNode) -> NavPath {
        let id = (node.renderID() as? String) ?? UUID().uuidString
        return .view(id: id, node: node)
    }
}
