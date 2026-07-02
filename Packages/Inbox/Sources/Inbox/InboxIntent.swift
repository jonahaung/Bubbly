// © 2026 Aung Ko Min

import Database

enum InboxIntent {
    case appear(CurrentUserModel)
    case refresh
    case disappear
}
