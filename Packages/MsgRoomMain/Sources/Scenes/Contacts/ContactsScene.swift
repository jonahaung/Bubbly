//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import XUI

public struct ContactsScene: View {

	let coordinator: AppCoordinator
	var currentUserRepository: CurrentUserRepository { coordinator.container.currentUserRepository }
	@State private var viewModel = ContactsViewModel()
    @State private var executor = ToolExecutor()

    enum DefaultContactDisplayType: String, CaseIterable {
        case chat = "Chat Contacts"
        case group = "Groups"
    }

    @AppStorage(
        "DefaultContactDisplayType",
        store: GroupStorage.shared.store
    ) private var defaultContactDisplay: DefaultContactDisplayType = .chat

    public init(
		coordinator: AppCoordinator
    ) {
		self.coordinator = coordinator
    }

    public var body: some View {
        List {
			Picker(
				"Contact Display",
				selection: $defaultContactDisplay
			) {
				let options: [DefaultContactDisplayType] = [.chat, .group]
				ForEach(options, id: \.self) { each in
					Text(each.rawValue)
				}
			}
			.pickerStyle(.palette)
			.listRowBackground(Color.clear)
			.listRowInsets(.init())
			AsyncButton {
				Loading.show(true)
				await viewModel.syncContacts()
				Loading.show(false)
			} label: {
				Label("Sync Contact", systemSymbol: .personCropSquare)
			}
			AsyncButton {
				Loading.show(true)
				await viewModel
					.syncGroups(currentUserId: currentUserRepository.model.uid)
				Loading.show(false)
			} label: {
				Label("Sync Groups", systemSymbol: .arrow2Squarepath)
			}
            switch defaultContactDisplay {
            case .group:
                groupsSection
            case .chat:

                contactsSections
            }
        }
		.redacted(reason: viewModel.isLoading ? [.placeholder] : [])
        .listSectionIndexVisibility(.visible)
        .navigationTitle("Contacts")

        .searchable(
			text: $viewModel.searchText,
            placement: .toolbar,
            prompt: "Search Contacts"
        )
        .onSubmit(of: .search) {
            executeContactsSearch()
        }
		.task {
			await viewModel.task()
		}
		.refreshable {
			
			await viewModel.refresh()
		}

    }

    private var actionSection: some View {
        Section {
            switch defaultContactDisplay {
            case .chat:
                AsyncButton {
                    Loading.show(true)
					await viewModel.syncContacts()
                    Loading.show(false)
                } label: {
                    Label("Sync Contact", systemSymbol: .personCropSquare)
                }
                AsyncButton {
                    Loading.show(true)
					await viewModel
						.syncGroups(currentUserId: currentUserRepository.model.uid)
                    Loading.show(false)
                } label: {
                    Label("Sync Groups", systemSymbol: .arrow2Squarepath)
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
                    Loading.show(true)
					await viewModel
						.syncGroups(currentUserId: currentUserRepository.model.uid)
                    Loading.show(false)
                } label: {
                    Label("Sync Groups", systemSymbol: .arrow2Squarepath)
                }
            }
        }
    }

    private var groupsSection: some View {
        Section {
			if viewModel.groups.isEmpty {
                ContentUnavailableView(
                    "No Groups",
                    systemImage: "person.2.circle.fill"
                )
            } else {
				ForEach(viewModel.groups) { group in
                    ConversationGroupCell(group: group)
                }
            }
        }
    }

    private var contactsSections: some View {
		let sections: [(String, [Contact])] = createSections(from: viewModel.displayContacts)
        return ForEach(sections, id: \.0) { section in
            Section(section.0) {
                ForEach(section.1, id: \.uid) { contact in
                    ContactCell(contact) {
                        try await openConversation(for: contact)
                    }
                }
            }
            .sectionIndexLabel(section.0)
        }
    }

    private func openConversation(for contact: Contact) async throws {
        let id = await ConversationIDGenerator.generate(
            contact.uid,
            currentUserRepository.model.uid
        )
        if let url = DeepLinkCoordinator().url(for: .conversation(id: id)) {
            await MainActor.run {
                UIApplication.shared.open(url)
            }
        }
    }

    private func delete(at offsets: IndexSet, _ contacts: [Contact]) {
        Task {
            await withThrowingTaskGroup(of: Void.self) { group in
                for index in offsets {
                    group.addTask {
                        if let item = contacts[safe: index] {
//							try await viewModel.delete(uid: item.uid)
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

    private func executeContactsSearch() {
        Task {
            let executor = ToolExecutor()
            await executor.execute(
                tool: ContactsTool(),
				prompt: "search contacts that has the name: \(viewModel.searchText)",
                type: [ContactsTool.Arguments].self
            ) { models in
                models.map(\.generatedContent.jsonString).joined(separator: "\n - ")
            } clearForm: {

            }
        }
    }
}
