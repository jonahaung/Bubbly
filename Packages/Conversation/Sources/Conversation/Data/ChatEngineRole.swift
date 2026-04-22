//  ChatEngineRole.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import SwiftData
import FoundationModels

// MARK: - ChatEngineRole

@Generable
public enum ChatEngineRole: String, Codable, Hashable, CaseIterable {
    case user = "User"
    case assistant = "Assistant"
    case sender = "Sender"
}

extension MsgRecipient {
    var role: ChatEngineRole {
        switch self {
        case .outgoing:
            .sender
        case .incoming:
            .user
        case .system:
            .assistant
        }
    }
}
