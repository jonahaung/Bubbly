//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Services
import SwiftData
import SwiftUI
import XUI

@MainActor
@Observable
final class SettingsSceneViewModel: ErrorPresenter {
    private(set) var state: SettingsViewState

	private var currentUserRepository: CurrentUserRepository {
		coordinator.container.currentUserRepository
	 }
	private var appLauncher: AppLauncher { coordinator.appLauncher }
    private let reducer: SettingsReducer
	private let coordinator: AppCoordinator

    init(
        reducer: SettingsReducer = SettingsReducerImpl(),
		coordinator: AppCoordinator
    ) {
        self.reducer = reducer
		self.coordinator = coordinator
        state = SettingsViewState(
            currentUser: .empty,
            fontName: Self.readFontName(),
            chatCellVerticalSpacing: Self.readGroupInt(
                key: GroupStorageKey.layout(.chatMsgSpacing).value,
                defaultValue: Settings.Layout.chatMsgSpacing
            ),
            paginationPageSize: Self.readGroupInt(
                key: GroupStorageKey.limit(.paginationPageSize).value,
                defaultValue: 50
            ),
            minutesForChatMsgGrouping: Self.readGroupInt(
                key: GroupStorageKey.limit(.minutesForChatMsgGrouping).value,
                defaultValue: 15
            )
        )
        Task { @MainActor [weak self] in
            guard let self else {
                return
            }
            let currentUser = await self.currentUserRepository.model
            self.dispatch(.applyCurrentUser(currentUser))
        }
    }

    func send(_ intent: SettingsIntent) async {
        switch intent {
        case .openUserProfile:
            handleOpenUserProfile()
        case .signOut:
            await handleSignOut()
        case let .setChatCellVerticalSpacing(value):
            handleSetChatCellVerticalSpacing(value)
        case let .setPaginationPageSize(value):
            handleSetPaginationPageSize(value)
        case let .setMinutesForChatMsgGrouping(value):
            handleSetMinutesForChatMsgGrouping(value)
        case .openFileSystem:
            handleOpenFileSystem()
        case .openFontPicker:
            handleOpenFontPicker()
        case .cleanUpFileSystem:
            await handleCleanUpFileSystem()
        case .deleteMessages:
            await handleDeleteMessages()
        case .deleteContacts:
            await handleDeleteContacts()
        case .deleteConversations:
            await handleDeleteConversations()
        case .resetCryptoKeys:
            await handleResetCryptoKeys()
        case let .setFontName(value):
            handleSetFontName(value)
        }
    }

    private func dispatch(_ action: SettingsAction) {
        reducer.reduce(state: &state, action: action)
    }

    private func handleOpenUserProfile() {
        Router.shared
            .pushToNav(
                .view(
                    node: RenderNodeView(
						content: UserProfileView(coordinator: coordinator)
                    )
                )
            )
    }

    private func handleSignOut() async {
        do {
            try await appLauncher.resetGetStarted()
        } catch {
            await showError(error)
        }
    }

    private func handleSetChatCellVerticalSpacing(_ value: Int) {
        GroupStorage.shared.store.set(value, forKey: GroupStorageKey.layout(.chatMsgSpacing).value)
        dispatch(.setChatCellVerticalSpacing(value))
    }

    private func handleSetPaginationPageSize(_ value: Int) {
        GroupStorage.shared.store.set(
            value,
            forKey: GroupStorageKey.limit(.paginationPageSize).value
        )
        dispatch(.setPaginationPageSize(value))
    }

    private func handleSetMinutesForChatMsgGrouping(_ value: Int) {
        GroupStorage.shared.store.set(
            value,
            forKey: GroupStorageKey.limit(.minutesForChatMsgGrouping).value
        )
        dispatch(.setMinutesForChatMsgGrouping(value))
    }

    private func handleOpenFileSystem() {
//        Router.shared
//            .pushToNav(
//                .view(
//                    id: FolderExplorer.typeName,
//                    node: RenderNodeView(content: FolderExplorer())
//                )
//            )
    }

    private func handleOpenFontPicker() {
//        Router.shared
//            .pushToNav(
//                .view(
//                    id: FontPicker.typeName,
//                    node: RenderNodeView(content: XUI.FontPicker(selection: fontNameBinding))
//                )
//            )
    }

    private func handleCleanUpFileSystem() async {
        do {
            try Folder.documents?.delete()
        } catch {
            await showError(error)
        }
    }

    private func handleDeleteMessages() async {
        await deleteAll(PMsg.self)
    }

    private func handleDeleteContacts() async {
        await deleteAll(PContact.self)
    }

    private func handleDeleteConversations() async {
        await deleteAll(PConversationProperties.self)
    }

    private func handleResetCryptoKeys() async {
        do {
            CryptoService.shared.forceReload(for: state.currentUser.uid)
            try await currentUserRepository.reload()
            let currentUser = await currentUserRepository.model
            dispatch(.applyCurrentUser(currentUser))
        } catch {
            await showError(error)
        }
    }

    private func handleSetFontName(_ value: String) {
        UserDefaults.standard.set(value, forKey: Self.fontNameKey)
        dispatch(.setFontName(value))
    }

    private func deleteAll<Model: PersistentModel>(_ type: Model.Type) async {
		guard let context = await Store.shared.modelContainer?.mainContext else {
            return
        }
        do {
            try context.transaction {
                let descriptor = FetchDescriptor<Model>()
                let models = try context.fetch(descriptor)
                for each in models {
                    context.delete(each)
                }
            }
        } catch {
            await showError(error)
        }
    }

    private var fontNameBinding: Binding<String> {
        Binding(
            get: { self.state.fontName },
            set: { [weak self] value in
                guard let self else {
                    return
                }
                Task { @MainActor in
                    await self.send(.setFontName(value))
                }
            }
        )
    }

    private static let fontNameKey = "fontName"

    private static func readFontName() -> String {
        UserDefaults.standard.string(forKey: fontNameKey) ?? UIFont.systemFontFamilyName
    }

    private static func readGroupInt(key: String, defaultValue: Int) -> Int {
        if GroupStorage.shared.store.object(forKey: key) == nil {
            return defaultValue
        }
        return GroupStorage.shared.store.integer(forKey: key)
    }
}

extension CurrentUserModel: @retroactive PhotoGalleryItem {
    public var galleryURL: URL? {
        .init(string: photoURL)
    }

    public var galleryTitle: String? {
        name
    }
}
