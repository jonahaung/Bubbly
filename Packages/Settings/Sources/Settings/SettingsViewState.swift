//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database

public struct SettingsViewState {
    let currentUser: CurrentUserModel
    let fontName: String
    let chatCellVerticalSpacing: Int
    let paginationPageSize: Int
    let minutesForChatMsgGrouping: Int
}
