// © 2026 Aung Ko Min

import Combine
import Database
import Foundation
import Observation
import Services
import XUI

@MainActor
@Observable
public final class InboxViewModel: ErrorPresenter {
    private(set) var state: InboxViewState

    private let manager: InboxManager
    private let observeInbox: ObserveInboxUseCase
    private let refreshInbox: RefreshInboxUseCase
    private let latestSnapshot: LatestInboxSnapshotUseCase
    private let cancelBag: CancelBag = .init()

    public init() {
        let manager = InboxManager()
        self.manager = manager
        let repository = InboxRepositoryImpl(manager: manager)
        observeInbox = ObserveInboxUseCaseImpl(repository: repository)
        refreshInbox = RefreshInboxUseCaseImpl(repository: repository)
        latestSnapshot = LatestInboxSnapshotUseCaseImpl(repository: repository)
        state = InboxViewState(items: [], isLoading: false, error: nil)
        observeManagerChanges()
    }

    func send(_ intent: InboxIntent) async {
        switch intent {
        case let .appear(currentUser):
            await handleAppear(currentUser)
        case .refresh:
            Task { await handleRefresh() }
        case .disappear:
            handleDisappear()
        }
    }

    private func handleAppear(_ currentUser: CurrentUserModel) async {
        observeInboxChanges()
        state = updatedState(isLoading: true, error: nil)
        do {
            let snapshot = try await observeInbox.execute(currentUser: currentUser)
            state = makeState(snapshot: snapshot, isLoading: false, error: nil)
        } catch {
            state = updatedState(isLoading: false, error: error.localizedDescription)
            await showError(error)
        }
    }

    private func handleRefresh() async {
        print("refreshing")
        state = updatedState(isLoading: true, error: nil)
        do {
            let snapshot = try await refreshInbox.execute()
            print(snapshot)
            state = makeState(snapshot: snapshot, isLoading: false, error: nil)
        } catch {
            state = updatedState(isLoading: false, error: error.localizedDescription)
            await showError(error)
        }
    }

    private func handleDisappear() {
        cancelBag.cancel()
    }

    private func observeInboxChanges() {
        NotificationCenter.default
            .publisher(for: .inboxChanges)
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                guard let self else {
                    return
                }

                Task { await self.handleRefresh() }
            }
            .store(in: cancelBag)
    }

    private func observeManagerChanges() {
        withObservationTracking {
            _ = manager.items.count
        } onChange: { [weak self] in
            guard let self else {
                return
            }

            Task { @MainActor in
                let snapshot = await latestSnapshot.execute()
                state = makeState(
                    snapshot: snapshot,
                    isLoading: state.isLoading,
                    error: state.error,
                )
                observeManagerChanges()
            }
        }
    }

    private func makeState(snapshot: InboxSnapshot, isLoading: Bool,
                           error: String?) -> InboxViewState
    {
        InboxViewState(items: snapshot.items, isLoading: isLoading, error: error)
    }

    private func updatedState(isLoading: Bool, error: String?) -> InboxViewState {
        InboxViewState(items: state.items, isLoading: isLoading, error: error)
    }
}
