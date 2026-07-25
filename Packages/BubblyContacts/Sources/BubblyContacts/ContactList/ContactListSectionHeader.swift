//  ContactListSectionHeader.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import SwiftUI

struct ContactListSectionHeader: View {
    let title: String

    var body: some View {
        Text(title)
            .font(.footnote)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity, alignment: .leading)
    }
}
