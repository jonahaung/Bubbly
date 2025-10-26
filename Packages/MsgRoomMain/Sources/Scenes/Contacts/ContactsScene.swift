//
//  ContactsScene.swift
//  Bubbly
//
//  Created by Aung Ko Min on 28/4/25.
//

import SwiftUI
import Services
import SFSafeSymbols
import XUI
import Database
import Core

@MainActor
public struct ContactsScene: View {

	@Environment(ContactStore.self) private var contactStore
	@State private var viewModel: ContactsViewModel = .init()
	@Environment(Router.self) private var router

	enum DefaultContactDisplayType: String, CaseIterable {
		case chat = "Chat Contacts"
		case all = "All Contacts"
		case group = "Groups"
	}
	@AppStorage(
		"DefaultContactDisplayType",
		store: GroupAppStorage.shared.store
	) private var defaultContactDisplay: DefaultContactDisplayType = .all

	public init() {}

	public var body: some View {
		List {
			Section {
				Picker.init(
					"Contact Display",
					selection: $defaultContactDisplay) {
						ForEach(
							contactStore.conversationGroups.isEmpty ? [DefaultContactDisplayType.chat, .all] : [.chat, .group, .all],
							id: \.self
						) { each in
							Text(each.rawValue)
						}
					}
					.pickerStyle(.segmented)
					.listRowInsets(.init())
			}
			.listRowBackground(Color.clear)
			switch defaultContactDisplay {
			case .group:
				Section {
					if contactStore.conversationGroups.isEmpty {
						ContentUnavailableView(
							"No Groups",
							systemImage: "person.2.circle.fill")
					} else {
						ForEach(contactStore.conversationGroups, id: \.uid) { group in
							ConversationGroupCell(group: group)
						}
					}
				}
			case .chat, .all:
				ForEach(viewModel.groups, id: \.0) { group in
					Section {
						ForEach(group.1, id: \.uid) { contact in
							ContactCell(contact) {
								ConversationInitializer.start(conversation: AnyConversation(.contact(contact)))
							}
						}
					}
				}
			}
		}
		.navigationTitle("MsgRoom")
		.toolbar {
			ToolbarItem(placement: .topBarTrailing) {
				Text("New Group")
					.presentSheet {
						NavigationView {
							CreateGroupScene()
						}
						.interactiveDismissDisabled()
					}
			}
			ToolbarItem(placement: .topBarLeading) {
				if viewModel.loading {
					ProgressView().controlSize(.mini)
				} else {
					Button {
						Task.detached(priority: .background) {
							await viewModel
								.syncContacts(store: contactStore)
						}
					} label: {
						Text("Sync Contacts")
					}
				}
			}
		}
		.task(id: defaultContactDisplay) {
			switch defaultContactDisplay {
			case .all:
				viewModel.createSections(from: contactStore.contacts)
			case .chat:
				viewModel
					.createSections(
						from: contactStore.contacts.filter { $0.isChatAvailable }
					)
			case .group:
				break
			}
		}
		.refreshable {
			try? await contactStore.refreshData()
		}
	}

	private func delete(at offsets: IndexSet, _ contacts: [Contact]) {
		Task {
			await withThrowingTaskGroup(of: Void.self) { group in
				for index in offsets {
					group.addTask {
						if let item = contacts[safe: index] {
							try await contactStore.delete(uid: item.uid)
						}
					}
				}
			}
			viewModel.createSections(from: contactStore.contacts)
		}
	}
}
