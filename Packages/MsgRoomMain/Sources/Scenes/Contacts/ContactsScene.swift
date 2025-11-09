//
//  ContactsScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import XUI

@MainActor
public struct ContactsScene: View {
    @Environment(ContactStore.self) private var store
    @State private var viewModel: ContactsViewModel = .init()
    @Environment(Router.self) private var router

    enum DefaultContactDisplayType: String, CaseIterable {
        case chat = "Chat Contacts"
        case group = "Groups"
    }

    @AppStorage(
        "DefaultContactDisplayType",
        store: GroupStorage.shared.store
    ) private var defaultContactDisplay: DefaultContactDisplayType = .chat

    public init() {}

    public var body: some View {
        List {
            Section {
                switch defaultContactDisplay {
                case .chat:
                    AsyncButton {
                        await viewModel.syncContacts(store: store)
                    } label: {
                        Label("Sync Contact", systemSymbol: .personCropSquare)
                    }
                case .group:
                    Label("Create New Group", systemSymbol: .plusCircleFill)
                        .foregroundStyle(Color.accentColor)
                        .presentSheet {
                            NavigationView {
                                CreateGroupScene()
                            }
                            .interactiveDismissDisabled()
                        }
                    AsyncButton {
                        try await viewModel.syncGroups(store: store)
                    } label: {
                        Label("Sync Groups", systemSymbol: .arrow2Squarepath)
                    }
                }
            } header: {
                Picker(
                    "Contact Display",
                    selection: $defaultContactDisplay
                ) {
                    ForEach(
                        store.groups.isEmpty ? [DefaultContactDisplayType.chat] : [.chat, .group],
                        id: \.self
                    ) { each in
                        Text(each.rawValue)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.vertical)
            }

            switch defaultContactDisplay {
            case .group:
                Section {
                    if store.groups.isEmpty {
                        ContentUnavailableView(
                            "No Groups",
                            systemImage: "person.2.circle.fill"
                        )
                    } else {
                        ForEach(store.groups) { group in
                            ConversationGroupCell(group: group)
                        }
                    }
                }
            case .chat:
                ForEach(createSections(from: store.contacts), id: \.0) { group in
                    Section {
                        ForEach(group.1, id: \.uid) { contact in
                            ContactCell(contact) {
                                ConversationInitializer.start(conversation: AnyConversation(.contact(contact)))
                            }
                        }
                    } header: {
                        Text(group.0)
                    }
                }
            }
        }
        .listSectionIndexVisibility(.visible)
        .toolbar {
            if viewModel.loading {
                ToolbarItem(placement: .topBarTrailing) {
                    ProgressView().controlSize(.mini)
                }
            }
        }
        .task {
            try? await store.fetchData()
        }
        .refreshable {
            try? await store.refresh()
        }
    }

    private func delete(at offsets: IndexSet, _ contacts: [Contact]) {
        Task {
            await withThrowingTaskGroup(of: Void.self) { group in
                for index in offsets {
                    group.addTask {
                        if let item = contacts[safe: index] {
                            try await store.delete(uid: item.uid)
                        }
                    }
                }
            }
        }
    }

    private func createSections(from contacts: [Contact]) -> [(String, [Contact])] {
        let group = contacts.groupByKey(keyPath: \.firstCharacter)
        let items = group.map { ($0.key, $0.value) }
        return items.sorted(by: { lhs, rhs in
            lhs.0 < rhs.0
        })
    }
}
