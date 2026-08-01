//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import XUI

enum UserProfileIntent {
    case appear
    case refreshRemote
    case editName(String)
    case setPickedPhoto(PickedPhoto?)
    case resetChanges
    case saveChanges
    case signOut
    case removeDisplayName
}
