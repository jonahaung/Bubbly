import Database
import Observation

@MainActor
@Observable
final class ContactListManager {
    private(set) var contacts: [Contact] = []
    private(set) var groups: [Group] = []
    private(set) var isLoading = false
    private(set) var error: String?

    func setContacts(_ value: [Contact]) {
        contacts = value
    }

    func setGroups(_ value: [Group]) {
        groups = value
    }

    func setLoading(_ value: Bool) {
        isLoading = value
    }

    func setError(_ value: String?) {
        error = value
    }
}
