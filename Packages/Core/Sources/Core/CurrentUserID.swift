//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import FirebaseAuth

public var currentUserId: String? {
    Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))
}
