//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database

enum ContactsIntent {
    case appear
    case refresh
    case syncContacts
    case syncGroups
    case setSearchText(String)
}
