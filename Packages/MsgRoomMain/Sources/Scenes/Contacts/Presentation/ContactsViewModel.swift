import Database
import Observation
import Services

@MainActor
@Observable
final class ContactsViewModel: ErrorPresenter {
	private(set) var state: ContactsViewState

	private let manager: ContactsManager
	private let reducer: ContactsReducer
	private let taskRegistry = ContactsTaskRegistry()
	private let loadContacts: LoadContactsUseCase
	private let refreshContacts: RefreshContactsUseCase
	private let syncContacts: SyncContactsUseCase
	private let syncGroups: SyncGroupsUseCase
	private let setSearchText: SetContactsSearchTextUseCase
	private let latestSnapshot: LatestContactsSnapshotUseCase

	init(contactsRepository: ContactsRepositoryProtocol,
	     currentUserRepository: CurrentUserRepository,
	     reducer: ContactsReducer = ContactsReducerImpl())
	{
		let manager = ContactsManager()
		self.manager = manager
		self.reducer = reducer
		let repository = ContactsRepositoryImpl(
			manager: manager,
			contactsRepository: contactsRepository,
			currentUserRepository: currentUserRepository
		)
		loadContacts = LoadContactsUseCaseImpl(repository: repository)
		refreshContacts = RefreshContactsUseCaseImpl(repository: repository)
		syncContacts = SyncContactsUseCaseImpl(repository: repository)
		syncGroups = SyncGroupsUseCaseImpl(repository: repository)
		setSearchText = SetContactsSearchTextUseCaseImpl(repository: repository)
		latestSnapshot = LatestContactsSnapshotUseCaseImpl(repository: repository)
		state = ContactsViewState(isLoading: false, error: nil, searchText: "")
		observeManagerChanges()
	}

	func send(_ intent: ContactsIntent) async {
		switch intent {
		case .appear:
			await taskRegistry.run(key: .appear) { [weak self] in
				guard let self else { return }
				await handleAppear()
			}
		case .refresh:
			await taskRegistry.run(key: .refresh) { [weak self] in
				guard let self else { return }
				await handleRefresh()
			}
		case .syncContacts:
			await taskRegistry.run(key: .syncContacts) { [weak self] in
				guard let self else { return }
				await handleSyncContacts()
			}
		case .syncGroups:
			await taskRegistry.run(key: .syncGroups) { [weak self] in
				guard let self else { return }
				await handleSyncGroups()
			}
		case let .setSearchText(value):
			await handleSetSearchText(value)
		}
	}

	private func handleAppear() async {
		dispatch(.setLoading(true))
		dispatch(.setError(nil))
		do {
			let snapshot = try await loadContacts.execute()
			dispatch(.applySnapshot(snapshot))
		} catch {
			dispatch(.setLoading(false))
			dispatch(.setError(error.localizedDescription))
			await showError(error)
		}
	}

	private func handleRefresh() async {
		dispatch(.setLoading(true))
		dispatch(.setError(nil))
		do {
			let snapshot = try await refreshContacts.execute()
			dispatch(.applySnapshot(snapshot))
		} catch {
			dispatch(.setLoading(false))
			dispatch(.setError(error.localizedDescription))
			await showError(error)
		}
	}

	private func handleSyncContacts() async {
		dispatch(.setLoading(true))
		dispatch(.setError(nil))
		do {
			let snapshot = try await syncContacts.execute()
			dispatch(.applySnapshot(snapshot))
		} catch {
			dispatch(.setLoading(false))
			dispatch(.setError(error.localizedDescription))
			await showError(error)
		}
	}

	private func handleSyncGroups() async {
		dispatch(.setLoading(true))
		dispatch(.setError(nil))
		do {
			let snapshot = try await syncGroups.execute()
			dispatch(.applySnapshot(snapshot))
		} catch {
			dispatch(.setLoading(false))
			dispatch(.setError(error.localizedDescription))
			await showError(error)
		}
	}

	private func handleSetSearchText(_ value: String) async {
		let snapshot = await setSearchText.execute(value)
		dispatch(.applySnapshot(snapshot))
	}

	private func observeManagerChanges() {
		withObservationTracking {
			_ = manager.isLoading
			_ = manager.error
			_ = manager.searchText
		} onChange: { [weak self] in
			guard let self else {
				return
			}
			Task { @MainActor in
				let snapshot = await latestSnapshot.execute()
				dispatch(.applySnapshot(snapshot))
				observeManagerChanges()
			}
		}
	}

	private func dispatch(_ action: ContactsAction) {
		reducer.reduce(state: &state, action: action)
	}
}

public extension Contact {
	var firstCharacter: String {
		if let first = name.first {
			return String(first).uppercased()
		}
		return ""
	}
}
