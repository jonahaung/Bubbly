//  ConversationKind.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Shared
import Foundation

public enum ConversationKind: Codable, Sendable, Hashable {
    case contact(_ contact: Contact)
    case group(_ group: Group)
}
