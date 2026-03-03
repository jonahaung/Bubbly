//
// Copyright © 2026 Stream.io Inc. All rights reserved.
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
