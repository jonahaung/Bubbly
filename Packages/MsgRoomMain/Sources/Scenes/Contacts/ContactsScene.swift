import Core
import Database
import Services
import SFSafeSymbols
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
			actionSection
			switch defaultContactDisplay {
			case .group:
				groupsSection
			case .chat:
				contactsSections
			}
		}
		.listSectionIndexVisibility(.visible)
		.navigationTitle("Contacts")
		.toolbar {
			ToolbarItem(placement: .principal) {
				Picker(
					"Contact Display",
					selection: $defaultContactDisplay
				) {
					let options: [DefaultContactDisplayType] =
						store.groups.isEmpty ? [.chat] : [.chat, .group]
					ForEach(options, id: \.self) { each in
						Text(each.rawValue)
					}
				}
				.pickerStyle(.palette)
			}
		}
		.searchable(
			text: $viewModel.searchText,
			placement: .toolbar,
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

	// MARK: - Sections

	private var actionSection: some View {
		Section {
			switch defaultContactDisplay {
			case .chat:
				AsyncButton {
					Loading.show(true)
					await viewModel.syncContacts(store: store, currentUser: currentUser)
					Loading.show(false)
				} label: {
					Label("Sync Contact", systemSymbol: .personCropSquare)
				}
				AsyncButton {
					Loading.show(true)
					try await viewModel.syncGroups(store: store, currentUser: currentUser)
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
					try await viewModel.syncGroups(store: store, currentUser: currentUser)
					Loading.show(false)
				} label: {
					Label("Sync Groups", systemSymbol: .arrow2Squarepath)
				}
			}
		}
	}

	private var groupsSection: some View {
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
	}

	private var contactsSections: some View {
		// Precompute sections with explicit type to help the type checker
		let sections: [(String, [Contact])] = createSections(from: store.contacts)
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
		let id = ConversationIDGenerator.generate(contact.uid, currentUser.uid)
		if let url = DeepLinkCoordinator.shared.url(for: .conversation(id: id)) {
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
			await executor.execute(
				tool: ContactsTool(),
				prompt: "search contacts that has the name: \(viewModel.searchText)",
				type: [ContactsTool.Arguments].self
			) { models in
				models.map(\.generatedContent.jsonString).joined(separator: "\n - ")
			} clearForm: {
				viewModel.searchText = ""
			}
		}
	}
}
