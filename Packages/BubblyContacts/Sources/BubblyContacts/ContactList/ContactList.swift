import Core
import Database
import Services
import SwiftUI
import XUI

public struct ContactList: View {
    

    public init(coordinator: AppCoordinator) {
        self.coordinator = coordinator
        _viewModel = .init(
            wrappedValue: .init(
                currentUserRepository: coordinator.container
                    .currentUserRepository,
            ),
        )
    }

    // MARK: Public

    public var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Spacing.md) {
                Picker("Contact Display", selection: $defaultContactDisplay) {
                    ForEach(DefaultContactDisplayType.allCases, id: \.self) {
                        Text($0.rawValue)
                    }
                }
                .pickerStyle(.segmented)

                if let error = viewModel.state.error {
                    Text(error)
                        .foregroundStyle(.red)
                        .padding(.horizontal, Padding.sm)
                }

                switch defaultContactDisplay {
                case .group:
                    ScrollSection(data: viewModel.state.groups) { group in
                        ConversationGroupCell(group: group)
                    }
                case .chat:
                    ForEach(viewModel.state.sections) { section in
                        ScrollSection(data: section.items) { contact in
                            ContactCell(contact) {
                                await openConversation(for: contact)
                            }
                            .id(contact.uid)
                        } header: {
                            HStack(alignment: .bottom) {
                                Text(section.title)
                                    .foregroundStyle(Color.secondaryText)
                                    .font(.footnote)

                                Spacer()
                            }
                        }
                        .id(section.id)
                    }
                }
            }
        }
        .groupScrollViewStyle()
        .navigationTitle(TabPath.contacts.name)
        .navigationSubtitle(TabPath.contacts.systemName)
        .searchable(
            text: $searchText,
            placement: .toolbarPrincipal,
            prompt: "Search Contacts",
        )
        .toolbar {
            ToolbarItemGroup {
                switch defaultContactDisplay {
                case .chat:
                    AsyncButton {
                        await viewModel.send(.syncContacts)
                    } label: {
                        Label(
                            "Sync",
                            systemImage:
                            "arrow.trianglehead.2.clockwise.rotate.90",
                        )
                        .labelStyle(.iconOnly)
                    }
                    .disabled(viewModel.state.isLoading)
                case .group:
                    AsyncButton {
                        await viewModel.send(.syncGroups)
                    } label: {
                        Label(
                            "Sync Groups",
                            systemImage:
                            "person.2.arrow.trianglehead.counterclockwise",
                        )
                        .labelStyle(.iconOnly)
                    }
                    .disabled(viewModel.state.isLoading)
                    Button {
                        coordinator.router.presentModel(
                            .view(
                                node: NavigationView { CreateGroupScene() }
                                    .interactiveDismissDisabled()
                                    .opaqueView(),
                            ),
                        )
                    } label: {
                        Label("New Group", systemImage: "plus")
                            .labelStyle(.iconOnly)
                    }
                    .disabled(viewModel.state.isLoading)
                }
            }
        }
        .task {
            await viewModel.send(.appear)
        }
        .refreshable {
            await viewModel.send(.refresh)
        }
        .onSubmit(of: .search) {
            executeContactsSearch()
        }
        .onChange(of: searchText) { _, newValue in
            Task {
                await viewModel.send(.setSearchText(newValue))
            }
        }
        .onChange(of: viewModel.state.searchText) { _, newValue in
            guard searchText != newValue else {
                return
            }

            searchText = newValue
        }
        .onChange(of: viewModel.state.isLoading) { _, newValue in
            Loading.show(newValue)
        }
    }

    

    enum DefaultContactDisplayType: String, CaseIterable {
        case chat = "Chat Contacts"
        case group = "Groups"
    }

    

    @State private var viewModel: ContactListViewModel
    @State private var executor: ToolExecutor = .init()
    @State private var searchText = ""

    @AppStorage("DefaultContactDisplayType", store: GroupStorage.shared.store)
    private var defaultContactDisplay: DefaultContactDisplayType = .chat

    private let coordinator: AppCoordinator

    private func openConversation(for contact: Contact) async {
        let currentUser = await coordinator.container.currentUserRepository
            .model
        let currentUserId = currentUser.uid
        let id = ConversationIDGenerator.generate(contact.uid, currentUserId)

        guard
            let url = coordinator.deeplinkCoordinator.url(
                for: .conversation(conID: id),
            )
        else {
            return
        }

        await MainActor.run {
            UIApplication.shared.open(url)
        }
    }

    private func executeContactsSearch() {
        Task {
            await executor.execute(
                tool: ContactsTool(),
                prompt: "search contacts that has the name: \(searchText)",
                type: [ContactsTool.Arguments].self,
            ) {
                $0.map(\.generatedContent.jsonString).joined(separator: "\n - ")
            } clearForm: {}
        }
    }
}
