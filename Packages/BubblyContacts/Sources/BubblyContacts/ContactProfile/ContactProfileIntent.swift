//  ContactProfileIntent.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Database

enum ContactProfileIntent {
    case appear
    case refresh
    case updateContact(Contact)
    case updateProperties(ConversationProperties)
    case deleteMessages
}
