//  ContactListToolbar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI

struct ContactListToolbar: ToolbarContent {
    let mode: ContactListDisplayMode
    let isLoading: Bool
    let syncContacts: () async -> Void
    let syncGroups: () async -> Void
    let createGroup: () -> Void

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            if mode == .group {
                AsyncButton(action: syncGroups) {
                    Label(
                        "Sync Groups",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise"
                    )
                }
                .disabled(isLoading)

                Button("New Group", systemImage: "plus", action: createGroup)
                    .disabled(isLoading)
            } else {
                AsyncButton(action: syncContacts) {
                    Label(
                        "Sync Contacts",
                        systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }
                .disabled(isLoading)
            }
        }
    }
}
