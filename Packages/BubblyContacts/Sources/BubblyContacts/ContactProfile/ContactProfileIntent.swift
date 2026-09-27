import Database
import Shared
enum ContactProfileIntent {
    case appear
    case refresh
    case updateContact(Contact)
    case updateProperties(ConversationProperties)
    case deleteMessages
}
