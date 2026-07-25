//  ContactListContactSections.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

struct ContactListContactSections: View {
    let sections: [ContactListSection]
    let selection: (Contact) async -> Void

    var body: some View {
        ForEach(sections) { section in
            ScrollSection(data: section.contacts) { contact in
                ContactCell(contact) {
                    await selection(contact)
                }
            } header: {
                ContactListSectionHeader(title: section.id)
            }
        }
    }
}
