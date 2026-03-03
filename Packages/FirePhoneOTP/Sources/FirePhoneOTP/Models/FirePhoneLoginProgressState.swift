//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import FirebaseAuth
import Foundation

enum FirePhoneLoginProgressState: Hashable {
    case none, loading
    case loggedIn(User, isNewUser: Bool)
}
