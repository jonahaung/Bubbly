//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database

enum InboxIntent {
    case appear(CurrentUserModel)
    case refresh
    case disappear
}
