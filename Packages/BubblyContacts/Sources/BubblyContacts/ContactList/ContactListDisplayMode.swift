//  ContactListDisplayMode.swift
//
//  Copyright © 2026 Aung Ko Min.
//

enum ContactListDisplayMode: String, CaseIterable, Identifiable {
    case chat = "Chat Contacts"
    case phone = "Phone Contacts"
    case group = "Groups"

    var id: Self {
        self
    }
}
