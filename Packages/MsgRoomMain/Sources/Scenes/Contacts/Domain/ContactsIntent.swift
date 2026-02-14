import Database

enum ContactsIntent {
	case appear
	case refresh
	case syncContacts
	case syncGroups
	case setSearchText(String)
}
