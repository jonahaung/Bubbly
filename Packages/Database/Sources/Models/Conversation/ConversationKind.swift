//
//  ConversationKind.swift
//  Database
//
//  Created by Aung Ko Min on 25/10/25.
//

import Foundation

public enum ConversationKind: Codable, Sendable, Hashable {
    case contact(_ contact: Contact)
    case group(_ group: Group)
}
