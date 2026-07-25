//  ContactListGroups.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database

struct ContactListGroups: View {
    let groups: [Database.Group]

    var body: some View {
        ScrollSection(data: groups) { group in
            ConversationGroupCell(group: group)
        }
    }
}
