//  ContactListSection.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database

struct ContactListSection: Identifiable, Sendable {
    let id: String
    let contacts: [Contact]
}
