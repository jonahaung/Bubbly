import Database

enum ContactListIntent {
    case appear
    case refresh
    case setSearchText(String)
    case syncContacts
    case syncGroups
}
