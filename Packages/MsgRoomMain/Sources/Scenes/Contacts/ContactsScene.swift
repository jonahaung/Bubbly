//
//  ContactsScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import Core
import Database
import SFSafeSymbols
import Services
import SwiftUI
import XUI

public struct ContactsScene: View {

	@Environment(ContactStore.self) private var store
	@State private var viewModel: ContactsViewModel = .init()
	@Environment(Router.self) private var router
	@Environment(\.currentUser) private var currentUser
	@State private var executor = ToolExecutor()

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
					AsyncButton {
						try await viewModel.syncGroups(store: store)
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
					Section(group.0) {
						ForEach(group.1, id: \.uid) { contact in
							ContactCell(contact) {
								try await ConversationInitializer
									.start(
										conversation: Conversation(
											.contact(contact),
											properties:
												ConversationPropertiesRepo
												.getOrCreateMain(
													for: ConversationIDGenerator
														.generate(currentUser.uid, contact.uid)
												)
										)
									)
							}
						}
					}
					.sectionIndexLabel(group.0)
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
		.searchable(
			text: $viewModel.searchText,
			placement: .automatic,
			prompt: "Search Contacts"
		)
		.onSubmit(of: .search) {
			executeContactsSearch()
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

	private func executeContactsSearch() {
		Task {
			let executor = ToolExecutor()
			await executor
				.execute(
					tool: ContactsTool(),
					prompt: "search contacts that has the name: \(viewModel.searchText)",
					type: [ContactsTool.Arguments].self) { models in
						return models.map{ $0.generatedContent.jsonString }.joined(separator: "\n - ")
					} clearForm: {
						viewModel.searchText = ""
					}
		}
	}
}
