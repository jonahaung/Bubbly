//  ContactListContentView.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database

struct ContactListContentView: View {
    let mode: ContactListDisplayMode
    let searchText: String
    let chatSections: [ContactListSection]
    let phoneSections: [ContactListSection]
    let groups: [Database.Group]
    let isLoading: Bool
    let errorMessage: String?
    let openConversation: (Contact) async -> Void
    let retry: () async -> Void

    var body: some View {
        if isLoading, !hasVisibleContent {
            ProgressView()
                .controlSize(.mini)
                .frame(maxWidth: .infinity)
                .padding(.vertical)
                .accessibilityLabel("Loading contacts")
        } else if let errorMessage, !hasVisibleContent {
            ContentUnavailableView {
                Label("Unable to Load Contacts", systemImage: "exclamationmark.triangle")
            } description: {
                Text(errorMessage)
            } actions: {
                AsyncButton(action: retry) {
                    Text("Try Again")
                }
            }
        } else if !hasVisibleContent {
            if searchText.isEmpty {
                ContentUnavailableView(
                    emptyTitle,
                    systemImage: emptySystemImage,
                    description: Text(emptyDescription)
                )
            } else {
                ContentUnavailableView.search
            }
        } else {
            switch mode {
            case .chat:
                ContactListContactSections(
                    sections: chatSections,
                    selection: openConversation
                )
            case .phone:
                ContactListPhoneSections(sections: phoneSections)
            case .group:
                ContactListGroups(groups: groups)
            }

            if let errorMessage {
                Label(errorMessage, systemImage: "exclamationmark.triangle")
                    .foregroundStyle(.red)
            }
        }
    }

    private var hasVisibleContent: Bool {
        switch mode {
        case .chat:
            !chatSections.isEmpty
        case .phone:
            !phoneSections.isEmpty
        case .group:
            !groups.isEmpty
        }
    }

    private var emptyTitle: String {
        switch mode {
        case .chat:
            "No Chat Contacts"
        case .phone:
            "No Phone Contacts"
        case .group:
            "No Groups"
        }
    }

    private var emptySystemImage: String {
        mode == .group ? "person.3" : "person.crop.circle"
    }

    private var emptyDescription: String {
        switch mode {
        case .chat:
            "Sync contacts to find people who use Bubbly."
        case .phone:
            "Allow Contacts access to display people from this device."
        case .group:
            "Create a group to start a shared conversation."
        }
    }
}
