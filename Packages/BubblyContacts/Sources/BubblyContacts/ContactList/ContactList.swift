//  ContactList.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import Shared
import SwiftUI
import Database
import Services

public struct ContactList: View {

    @State private var viewModel: ContactListViewModel
    @AppStorage("DefaultContactDisplayType", store: GroupStorage.shared.store)
    private var displayMode: ContactListDisplayMode = .chat
    private let coordinator: AppCoordinator

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _viewModel = .init(wrappedValue: .init())
    }

    public var body: some View {
        ScrollView {
            LazyVStack(
                alignment: .leading,
                spacing: Spacing.md,
                pinnedViews: .sectionHeaders
            ) {
                Section {
                    ContactListContentView(
                        mode: displayMode,
                        searchText: viewModel.searchText,
                        chatSections: viewModel.chatSections,
                        phoneSections: viewModel.phoneSections,
                        groups: viewModel.groups,
                        isLoading: viewModel.isLoading,
                        errorMessage: viewModel.errorMessage,
                        openConversation: openConversation,
                        retry: viewModel.retry
                    )
                } header: {
                    ContactListModePicker(selection: $displayMode)
                }
            }
        }
        .groupScrollViewStyle()
        .navigationTitle(TabPath.contacts.name)
        .navigationSubtitle(TabPath.contacts.systemName)
        .searchable(
            text: $viewModel.searchText,
            placement: .navigationBarDrawer(displayMode: .automatic),
            prompt: "Search Contacts"
        )
        .toolbar {
            ContactListToolbar(
                coordinator: coordinator, viewModel: viewModel, displayMode: displayMode
            )
        }
        .task {
            await viewModel.perform(.load)
        }
        .refreshable {
            await viewModel.perform(.refresh)
        }
    }

    private func openConversation(for contact: Contact) async {
        if contact.isChatAvailable {
            guard let contact = await viewModel.resolveContact(contact) else {
                return
            }
            let currentUser = await coordinator.container.currentUserRepository.model
            let id = ConversationIDGenerator.generate(contact.uid, currentUser.uid)
            guard let url = DeeplinkCodec.standard.url(for: .conversation(conID: id)) else {
                return
            }
            await UIApplication.shared.open(url)
        } else {
        }

    }
}
