//  ContactProfileViewState.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Database

struct ContactProfileViewState {
    var contact: Contact
    var properties: ConversationProperties
    var isLoading: Bool
    var isDeletingMessages: Bool
    var error: String?
}
