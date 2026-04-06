//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import FirebaseAuth

public var currentUserID: String? {
    Auth.auth().currentUser?.uid ?? GroupStorage.shared.string(for: .auth(.currentUserID))
}
