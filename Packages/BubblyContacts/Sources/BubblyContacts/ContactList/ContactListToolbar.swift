//  ContactListToolbar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Services
import Database

struct ContactListToolbar: ToolbarContent {

    let coordinator: AppCoordinator
    let viewModel: ContactListViewModel
    var displayMode: ContactListDisplayMode = .chat
    @State private var isLoading: Bool = false

    var body: some ToolbarContent {
        ToolbarItemGroup(placement: .topBarTrailing) {
            switch displayMode {
            case .chat:
                AsyncButton(action: syncContacts) {
                    Label(
                        "Sync Contacts",
                        systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }
                .disabled(isLoading)
            case .phone:
                AsyncButton(action: uploadContacts) {
                    Label(
                        "Sync Contacts",
                        systemImage: "arrow.trianglehead.2.clockwise.rotate.90"
                    )
                }
                .disabled(isLoading)
            case .group:
                AsyncButton(action: syncGroups) {
                    Label(
                        "Sync Groups",
                        systemImage: "person.2.arrow.trianglehead.counterclockwise"
                    )
                }
                .disabled(isLoading)

                Button(
                    "New Group",
                    systemImage: "plus",
                    action: presentCreateGroup
                )
                .disabled(isLoading)
            }
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

    private func uploadContacts() async {
        isLoading = true
        defer {
            isLoading = false
        }
        do {
            try await AsyncOrderedStream
                .mapOrdered(
                    inputs: viewModel.phoneSections.flatMap { $0.contacts }
                ) { contact in
                    try await HTTPClient.shared.updateContact(contact)
                }
        } catch {
            log(error)
        }
    }
}
