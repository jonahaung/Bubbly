//  ContactListPhoneSections.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI

struct ContactListPhoneSections: View {
    let sections: [ContactListSection]

    var body: some View {
        ForEach(sections) { section in
            ScrollSection(data: section.contacts) { contact in
                ContactListPhoneRow(contact: contact)
            } header: {
                ContactListSectionHeader(title: section.id)
            }
        }
    }
}
