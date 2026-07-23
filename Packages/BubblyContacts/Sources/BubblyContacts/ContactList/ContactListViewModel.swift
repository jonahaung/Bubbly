import Database
import Observation
import Services

@MainActor
@Observable
final class ContactListViewModel {
    private(set) var state: ContactListViewState

    private let reducer: ContactListReducer
    private let taskRegistry: ContactListTaskRegistry = .init()
    private let loadUseCase: LoadContactListUseCase
    private let refreshUseCase: RefreshContactListUseCase
    private let syncContactsUseCase: SyncContactListContactsUseCase
    private let syncGroupsUseCase: SyncContactListGroupsUseCase

    init(reducer: ContactListReducer = ContactListReducerImpl()) {
        self.reducer = reducer
        let manager = ContactListManager()
        let repository = ContactListRepositoryImpl(manager: manager)
        loadUseCase = LoadContactListUseCaseImpl(repository: repository)
        refreshUseCase = RefreshContactListUseCaseImpl(repository: repository)
        syncContactsUseCase = SyncContactListContactsUseCaseImpl(repository: repository)
        syncGroupsUseCase = SyncContactListGroupsUseCaseImpl(repository: repository)
        state = .init(
            searchText: "",
            chatContacts: [],
            phoneContacts: [],
            groups: [],
            chatContactSections: [],
            phoneContactSections: [],
            isLoading: false,
            error: nil,
        )
    }

    func send(_ intent: ContactListIntent) async {
        switch intent {
        case .appear:
            await taskRegistry.run(key: .appear) { [weak self] in
                guard let self else {
                    return
                }
                await load()
            }
        case .refresh:
            await taskRegistry.run(key: .refresh) { [weak self] in
                guard let self else {
                    return
                }
                await refresh()
            }
        case let .setSearchText(value):
            dispatch(.setSearchText(value))
        case .syncContacts:
            await taskRegistry.run(key: .syncContacts) { [weak self] in
                guard let self else {
                    return
                }
                await syncContacts()
            }
        case .syncGroups:
            await taskRegistry.run(key: .syncGroups) { [weak self] in
                guard let self else {
                    return
                }
                await syncGroups()
            }
        }
    }

    private func load() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await loadUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        }
        catch {
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
        }
        catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func syncContacts() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await syncContactsUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        }
        catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func syncGroups() async {
        dispatch(.setLoading(true))
        dispatch(.setError(nil))
        do {
            let snapshot = try await syncGroupsUseCase.execute()
            dispatch(.applySnapshot(snapshot))
        }
        catch {
            dispatch(.setLoading(false))
            dispatch(.setError(error.localizedDescription))
        }
    }

    private func dispatch(_ action: ContactListAction) {
        reducer.reduce(state: &state, action: action)
    }
}
