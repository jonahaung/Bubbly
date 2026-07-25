//  ContactListPhoneRow.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct ContactListPhoneRow: View {
    let contact: Contact

    var body: some View {
        Label {
            LabeledContent(contact.name) {
                Text(contact.mobile)
                    .foregroundStyle(.secondary)
            }
        } icon: {
            ProfilePhoto(contact, size: .custom(25))
        }
        .labelIconToTitleSpacing(Spacing.lg)
        .padding(.horizontal, Padding.sm)
    }
}
