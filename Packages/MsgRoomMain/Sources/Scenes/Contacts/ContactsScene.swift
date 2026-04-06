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
		List {
			Section { actionSection } header: { displayPicker }

			switch defaultContactDisplay {
			case .group: groupsSection
			case .chat:  contactsSections
			}
		}
		.listSectionIndexVisibility(.visible)
		.navigationTitle(TabPath.contacts.name)
		.searchable(text: $viewModel.searchText, placement: .toolbar, prompt: "Search Contacts")
		.onSubmit(of: .search, executeContactsSearch)
		.task { await viewModel.task() }
		.refreshable { await viewModel.refresh() }
		.onChange(of: viewModel.displayContacts) { oldValue, newValue in
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

	@ViewBuilder
	var actionSection: some View {
		switch defaultContactDisplay {

		case .chat:
			asyncAction("Sync Contact", .personCropSquare) {
				await viewModel.syncContacts()
			}

			asyncAction("Sync Groups", .arrow2Squarepath) {
				await viewModel.syncGroups(currentUserId: currentUserRepository.model.uid)
			}

		case .group:
			Label("Create New Group", systemSymbol: .plusCircleFill)
				.foregroundStyle(Color.accentColor)
				.presentSheet {
					NavigationView { CreateGroupScene() }
						.interactiveDismissDisabled()
				}

			asyncAction("Sync Groups", .arrow2Squarepath) {
				await viewModel.syncGroups(currentUserId: currentUserRepository.model.uid)
			}
		}
	}

	func asyncAction(
		_ title: String,
		_ symbol: SFSymbol,
		action: @escaping () async -> Void
	) -> some View {
		AsyncButton {
			Loading.show(true)
			await action()
			Loading.show(false)
		} label: {
			Label(title, systemSymbol: symbol)
		}
	}

	var groupsSection: some View {
		Section {
			if viewModel.groups.isEmpty {
				ContentUnavailableView("No Groups", systemImage: "person.2.circle.fill")
			} else {
				ForEach(viewModel.groups, content: ConversationGroupCell.init)
			}
		}
	}

	var contactsSections: some View {
		ForEach(sections) { section in
			Section(section.title) {
				ForEach(section.items, id: \.uid) { contact in
					ContactCell(contact) {
						try await openConversation(for: contact)
					}
				}
			}
			.sectionIndexLabel(section.title)
		}
	}
}

// MARK: - Actions

private extension ContactsScene {

	func openConversation(for contact: Contact) async throws {
		let id = await ConversationIDGenerator.generate(
			contact.uid,
			currentUserRepository.model.uid
		)

		guard let url = DeepLinkCoordinator().url(for: .conversation(id: id)) else { return }
		await MainActor.run { UIApplication.shared.open(url) }
	}

	func executeContactsSearch() {
		Task {
			await executor.execute(
				tool: ContactsTool(),
				prompt: "search contacts that has the name: \(viewModel.searchText)",
				type: [ContactsTool.Arguments].self
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
		guard new != sections else { return }

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

// MARK: - Models

private struct ContactSection: Identifiable, Equatable {
	let id: String
	var title: String
	var items: [Contact]
}
