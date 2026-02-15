import Core
import Database
import Services
import SFSafeSymbols
import SwiftUI
import XUI

public struct ContactsScene: View {
	let contactsRepository: ContactsRepositoryProtocol
	let currentUserRepository: CurrentUserRepository
	let router: Router

	@State private var viewModel: ContactsViewModel
	@State private var executor = ToolExecutor()

	enum DefaultContactDisplayType: String, CaseIterable {
		case chat = "Chat Contacts"
		case group = "Groups"
	}

	@AppStorage(
		"DefaultContactDisplayType",
		store: GroupStorage.shared.store
	) private var defaultContactDisplay: DefaultContactDisplayType = .chat

	public init(router: Router,
	            contactsRepository: ContactsRepositoryProtocol,
	            currentUserRepository: CurrentUserRepository)
	{
		self.router = router
		self.contactsRepository = contactsRepository
		self.currentUserRepository = currentUserRepository
		_viewModel = .init(
			wrappedValue: ContactsViewModel(
				contactsRepository: contactsRepository,
				currentUserRepository: currentUserRepository
			)
		)
	}

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
						(contactsRepository.groups.isEmpty) ? [.chat] : [.chat, .group]
					ForEach(options, id: \.self) { each in
						Text(each.rawValue)
					}
				}
				.pickerStyle(.palette)
			}
		}
		.searchable(
			text: Binding(
				get: { viewModel.state.searchText },
				set: { newValue in
					Task { await viewModel.send(.setSearchText(newValue)) }
				}
			),
			placement: .toolbar,
			prompt: "Search Contacts"
		)
		.onSubmit(of: .search) {
			executeContactsSearch()
		}
		.task {
			await viewModel.send(.appear)
		}
		.refreshable {
			await viewModel.send(.refresh)
		}
	}

	private var actionSection: some View {
		Section {
			switch defaultContactDisplay {
			case .chat:
				AsyncButton {
					Loading.show(true)
					await viewModel.send(.syncContacts)
					Loading.show(false)
				} label: {
					Label("Sync Contact", systemSymbol: .personCropSquare)
				}
				AsyncButton {
					Loading.show(true)
					await viewModel.send(.syncGroups)
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
					await viewModel.send(.syncGroups)
					Loading.show(false)
				} label: {
					Label("Sync Groups", systemSymbol: .arrow2Squarepath)
				}
			}
		}
	}

	private var groupsSection: some View {
		Section {
			if contactsRepository.groups.isEmpty {
				ContentUnavailableView(
					"No Groups",
					systemImage: "person.2.circle.fill"
				)
			} else {
				ForEach(contactsRepository.groups) { group in
					ConversationGroupCell(group: group)
				}
			}
		}
	}

	private var contactsSections: some View {
		let sections: [(String, [Contact])] = createSections(from: contactsRepository.contacts)
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
							try await contactsRepository.delete(uid: item.uid)
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
				prompt: "search contacts that has the name: \(viewModel.state.searchText)",
				type: [ContactsTool.Arguments].self
			) { models in
				models.map(\.generatedContent.jsonString).joined(separator: "\n - ")
			} clearForm: {
				Task { await viewModel.send(.setSearchText("")) }
			}
		}
	}
}
