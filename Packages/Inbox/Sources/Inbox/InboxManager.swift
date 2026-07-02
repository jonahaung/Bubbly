// © 2026 Aung Ko Min

import Database
import Observation

@MainActor
@Observable
final class InboxManager {
    private(set) var items: [InboxItem] = []
    private(set) var currentUser: CurrentUserModel = .empty

    func setCurrentUser(_ value: CurrentUserModel) {
        currentUser = value
    }

    func setItems(_ value: [InboxItem]) {
        items = value
    }
}
