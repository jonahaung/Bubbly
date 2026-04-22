//  HeaderModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Database

// MARK: - HeaderKind

enum HeaderKind: Hashable, Sendable {
    case conversation(Conversation)
}

// MARK: - HeaderModel

struct HeaderModel: Hashable, Sendable, Identifiable {
    let kind: HeaderKind
    var id: HeaderKind {
        kind
    }
}
