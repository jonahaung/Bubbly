//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Observation

@MainActor
@Observable
final class ContactsManager {
    private(set) var isLoading = false
    private(set) var error: String?
    private(set) var searchText = ""

    func setLoading(_ value: Bool) {
        isLoading = value
    }

    func setError(_ value: String?) {
        error = value
    }

    func setSearchText(_ value: String) {
        searchText = value
    }
}
