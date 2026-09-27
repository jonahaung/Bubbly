//  ContactListSection.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Shared
struct ContactListSection: Identifiable, Sendable {
    let id: String
    let contacts: [Contact]
}
