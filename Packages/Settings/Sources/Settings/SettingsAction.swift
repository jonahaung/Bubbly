//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database

public enum SettingsAction {
    case applyCurrentUser(CurrentUserModel)
    case setFontName(String)
    case setChatCellVerticalSpacing(Int)
    case setPaginationPageSize(Int)
    case setMinutesForChatMsgGrouping(Int)
}
