//  ContactProfileViewModel.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Shared
import Database
import Observation

@MainActor
@Observable
final class ContactProfileViewModel {
    private(set) var state: ContactProfileViewState

    private let reducer: ContactProfileReducer
    private let taskRegistry: ContactProfileTaskRegistry = .init()
    private let loadUseCase: LoadContactProfileUseCase
    private let refreshUseCase: RefreshContactProfileUseCase
    private let updateContactUseCase: UpdateContactProfileContactUseCase
    private let updatePropertiesUseCase: UpdateContactProfilePropertiesUseCase
    private let deleteMessagesUseCase: DeleteContactProfileMessagesUseCase

    init(contact: Contact, reducer: ContactProfileReducer = ContactProfileReducerImpl()) {
        self.reducer = reducer
        let properties = ConversationProperties(uid: Conversation(.contact(contact)).uid)
        let manager = ContactProfileManager(contact: contact, properties: properties)
        let repository = ContactProfileRepositoryImpl(manager: manager)
        loadUseCase = LoadContactProfileUseCaseImpl(repository: repository)
        refreshUseCase = RefreshContactProfileUseCaseImpl(repository: repository)
        updateContactUseCase = UpdateContactProfileContactUseCaseImpl(repository: repository)
        updatePropertiesUseCase = UpdateContactProfilePropertiesUseCaseImpl(repository: repository)
        deleteMessagesUseCase = DeleteContactProfileMessagesUseCaseImpl(repository: repository)
        state = .init(
            contact: contact,
            properties: properties,
            isLoading: false,
            isDeletingMessages: false,
            error: nil
        )
    }

    func send(_ intent: ContactProfileIntent) async {
        switch intent {
        case .appear:
            await taskRegistry.run(key: .appear) { [weak self] in
                guard let self else { return }
                await load()
            }
        case .refresh:
            await taskRegistry.run(key: .refresh) { [weak self] in
                guard let self else { return }
                await refresh()
            }
        case let .updateContact(contact):
            await taskRegistry.run(key: .updateContact) { [weak self] in
                guard let self else { return }
                await updateContact(contact)
            }
        case let .updateProperties(properties):
            await taskRegistry.run(key: .updateProperties) { [weak self] in
                guard let self else { return }
                await updateProperties(properties)
            }
        case .deleteMessages:
            await taskRegistry.run(key: .deleteMessages) { [weak self] in
                guard let self else { return }
                await deleteMessages()
            }
        }
    }

    private func load() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await loadUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func refresh() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await refreshUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func updateContact(_ contact: Contact) async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await updateContactUseCase.execute(contact: contact)
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func updateProperties(_ properties: ConversationProperties) async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await updatePropertiesUseCase.execute(properties: properties)
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func deleteMessages() async {
        dispatch(.setDeletingMessages(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await deleteMessagesUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        } catch {
            dispatch(.setDeletingMessages(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func dispatch(_ action: ContactProfileAction) {
        reducer.reduce(state: &state, action: action)
    }
}
