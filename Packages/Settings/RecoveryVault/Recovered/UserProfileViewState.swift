//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database

struct UserProfileViewState: Equatable {
    let currentUser: CurrentUserModel
    let originalUser: CurrentUserModel
    let isLoading: Bool
    let error: String?
    let shouldDismiss: Bool
    let hasPickedPhoto: Bool
}
