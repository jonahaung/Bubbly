import Database
import Observation

@MainActor
@Observable
final class ContactProfileManager {
    private(set) var contact: Contact
    private(set) var properties: ConversationProperties
    private(set) var isLoading = false
    private(set) var isDeletingMessages = false
    private(set) var error: String?

    init(contact: Contact, properties: ConversationProperties) {
        self.contact = contact
        self.properties = properties
    }

    func setContact(_ value: Contact) {
        contact = value
    }

    func setProperties(_ value: ConversationProperties) {
        properties = value
    }

    func setLoading(_ value: Bool) {
        isLoading = value
    }

    func setDeletingMessages(_ value: Bool) {
        isDeletingMessages = value
    }

    func setError(_ value: String?) {
        error = value
    }
}
