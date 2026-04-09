//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

enum SettingsIntent {
    case openUserProfile
    case signOut
    case setChatCellVerticalSpacing(Int)
    case setPaginationPageSize(Int)
    case setMinutesForChatMsgGrouping(Int)
    case openFileSystem
    case openFontPicker
    case cleanUpFileSystem
    case deleteMessages
    case deleteContacts
    case deleteConversations
    case resetCryptoKeys
    case setFontName(String)
}
