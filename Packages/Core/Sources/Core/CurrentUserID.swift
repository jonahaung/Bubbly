// © 2026 Aung Ko Min

import FirebaseAuth

public var currentUserID: String? {
    Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))
}
