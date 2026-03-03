//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

enum ContactsAction {
    case setLoading(Bool)
    case setError(String?)
    case applySnapshot(ContactsSnapshot)
}
