// © 2026 Aung Ko Min

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import XUI

// MARK: - ContactsScene

public struct ContactsScene: View {
    let coordinator: AppCoordinator
    var currentUserRepository: CurrentUserRepository {
        coordinator.container.currentUserRepository
    }

    @State private var viewModel: ContactsViewModel = .init()
    @State private var executor: ToolExecutor = .init()
    @State private var sections: [ContactSection] = []

    enum DefaultContactDisplayType: String, CaseIterable {
        case chat = "Chat Contacts"
        case group = "Groups"
    }

    @AppStorage("DefaultContactDisplayType", store: GroupStorage.shared.store)
    private var defaultContactDisplay: DefaultContactDisplayType = .chat

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
    }

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                displayPicker
                switch defaultContactDisplay {
                case .group: groupsSection
                case .chat: contactsSections
                }
            }
            .padding(.horizontal, Padding.md)
        }
        .applyBackground()
        .navigationTitle(TabPath.contacts.name)
        .navigationSubtitle(TabPath.contacts.systemName)
        .searchable(
            text: $viewModel.searchText,
            placement: .toolbarPrincipal,
            prompt: "Search Contacts",
        )
        .toolbar {
            ToolbarItemGroup {
                Group {
                    switch defaultContactDisplay {
                    case .chat:
                        asyncAction("Sync", "arrow.trianglehead.2.clockwise.rotate.90") {
                            await viewModel.syncContacts()
                        }
                    case .group:
                        asyncAction("Sync", "person.2.arrow.trianglehead.counterclockwise") {
                            await viewModel
                                .syncGroups(currentUserId: currentUserRepository.model.uid)
                        }
                        asyncAction("New Group", "plus") {
                            coordinator.router
                                .presentModel(NavPath
                                    .view(node: NavigationView { CreateGroupScene() }
                                        .interactiveDismissDisabled()
                                        .opaqueView()))
                        }
                    }
                }
            }
        }
        .onSubmit(of: .search, executeContactsSearch)
        .onTask { await viewModel.task() }
        .refreshable { await viewModel.refresh() }
        .onChange(of: viewModel.displayContacts) { _, newValue in
            updateSections(newValue)
        }
    }
}

// MARK: - UI

private extension ContactsScene {
    var displayPicker: some View {
        Picker("Contact Display", selection: $defaultContactDisplay) {
            ForEach(DefaultContactDisplayType.allCases, id: \.self) { Text($0.rawValue) }
        }
        .pickerStyle(.segmented)
    }

    func asyncAction(
        _: String,
        _ symbol: String,
        action: @escaping () async -> Void,
    ) -> some View {
        AsyncButton {
            Loading.show(true)
            await action()
            Loading.show(false)
        } label: {
            Image(systemName: symbol)
        }
    }

    @ViewBuilder
    var groupsSection: some View {
        if viewModel.groups.isEmpty {
            ContentUnavailableView("No Groups", systemImage: "person.2.circle.fill")
        } else {
            VStack(alignment: .leading, spacing: Spacing.md) {
                ForEach(viewModel.groups, content: ConversationGroupCell.init)
                    .intersperse {
                        Divider()
                    }
            }
            .padding(Padding.md)
            .background(Color.appPrimary, in: .rect)
        }
    }

    var contactsSections: some View {
        ForEach(sections) { section in
            VStack(alignment: .leading, spacing: Spacing.xs) {
                HStack(alignment: .bottom) {
                    Text(section.title)
                        .foregroundStyle(Color.secondaryText)
                        .font(.footnote)

                    Spacer()
                }.padding(.horizontal, Padding.sm)
                VStack(alignment: .leading, spacing: Spacing.md) {
                    ForEach(section.items, id: \.uid) { contact in
                        ContactCell(contact) {
                            await openConversation(for: contact)
                        }
                        .id(contact.uid)
                    }.intersperse {
                        Divider()
                    }
                }
                .padding(Padding.md)
                .background(Color.appPrimary, in: .rect)
            }
            .id(section.id)
        }
    }
}

// MARK: - Actions

private extension ContactsScene {
    func openConversation(for contact: Contact) async {
        let id = await ConversationIDGenerator.generate(
            contact.uid,
            currentUserRepository.model.uid,
        )

        guard let url = coordinator.deeplinkCoordinator.url(for: .conversation(id: id)) else {
            return
        }

        await MainActor.run { UIApplication.shared.open(url) }
    }

    func executeContactsSearch() {
        Task {
            await executor.execute(
                tool: ContactsTool(),
                prompt: "search contacts that has the name: \(viewModel.searchText)",
                type: [ContactsTool.Arguments].self,
            ) {
                $0.map(\.generatedContent.jsonString).joined(separator: "\n - ")
            } clearForm: {}
        }
    }
}

// MARK: - Diffable Sections

private extension ContactsScene {
    func updateSections(_ contacts: [Contact]) {
        let new = buildSections(from: contacts)
        guard new != sections else {
            return
        }

        withAnimation(.smooth) {
            sections = new
        }
    }

    func buildSections(from contacts: [Contact]) -> [ContactSection] {
        contacts
            .groupByKey(keyPath: \.firstCharacter)
            .map { ContactSection(id: $0.key, title: $0.key, items: $0.value) }
            .sorted { $0.id < $1.id }
    }
}

// MARK: - ContactSection

private struct ContactSection: Identifiable, Equatable {
    let id: String
    var title: String
    var items: [Contact]
}
