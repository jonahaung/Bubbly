//  ContactList.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

public struct ContactList: View {
    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _viewModel = .init(wrappedValue: .init())
    }

    public var body: some View {
        @Bindable var viewModel = viewModel

        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                ContactListModePicker(selection: $displayMode)
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
            }
        }
        .groupScrollViewStyle()
        .navigationTitle(TabPath.contacts.name)
        .navigationSubtitle(TabPath.contacts.systemName)
        .searchable(
            text: $viewModel.searchText,
            placement: .toolbarPrincipal,
            prompt: "Search Contacts"
        )
        .toolbar {
            ContactListToolbar(
                mode: displayMode,
                isLoading: viewModel.isLoading,
                syncContacts: syncContacts,
                syncGroups: syncGroups,
                createGroup: presentCreateGroup
            )
        }
        .task {
            await viewModel.perform(.load)
        }
        .refreshable {
            await viewModel.perform(.refresh)
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    @State private var viewModel: ContactListViewModel
    @AppStorage("DefaultContactDisplayType", store: GroupStorage.shared.store)
    private var displayMode: ContactListDisplayMode = .chat

    private let coordinator: AppCoordinator

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

    private func syncContacts() async {
        await viewModel.perform(.syncContacts)
    }

    private func syncGroups() async {
        await viewModel.perform(.syncGroups)
    }

    private func presentCreateGroup() {
        coordinator.router.presentModel(
            .view(
                node: NavigationStack {
                    CreateGroupScene()
                }
                .interactiveDismissDisabled()
                .opaqueView()
            )
        )
    }
}
