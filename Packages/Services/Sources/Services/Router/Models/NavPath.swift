// © 2026 Aung Ko Min

import Database
import Foundation
import SwiftUI
import XUI

public enum NavPath: Sendable, Hashable, Identifiable, CaseNameReflectable {
    case conversationDetails(_ conversation: Conversation)
    case conversation(_ prefatchData: ConversationInitializer.PrefetchedData)
    case contactDetails(_ contact: Contact)
    case currentUserDetails
    case view(node: RenderNode)

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
        case .view:
            hasher.combine("view")
        }
    }

    public static func == (lhs: NavPath, rhs: NavPath) -> Bool {
        lhs.id == rhs.id
    }
}
