//  HeaderModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import XUI

enum HeaderKind: Hashable, Sendable {
    case conversation(Conversation)
}

struct HeaderModel: Hashable, Sendable, Identifiable {
    let kind: HeaderKind
    var id: HeaderKind {
        kind
    }
}
