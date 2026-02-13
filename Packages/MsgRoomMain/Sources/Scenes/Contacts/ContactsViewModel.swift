import Database
import Foundation
import Services
import XUI

@MainActor
@Observable
final class ContactsViewModel: ErrorPresenter {
	var loading: Bool = false
	var searchText = ""
	init() {}

	@concurrent
	func syncContacts(store: ContactsRepositoryProtocol?, currentUser _: CurrentUserModel) async {
		await setLoading(true)
		do {
			try await store?.syncContacts()
			await setLoading(false)
		} catch {
			await showError(error)
			await setLoading(false)
		}
	}

	@concurrent
	func syncGroups(store: ContactsRepositoryProtocol?,
	                currentUser: CurrentUserModel) async throws
	{
		await setLoading(true)
		do {
			try await store?.syncGroups(currentUser: currentUser)
			await setLoading(false)
		} catch {
			await showError(error)
			await setLoading(false)
		}
	}

	private func setLoading(_ isLoading: Bool) {
		loading = isLoading
	}
}

public extension Contact {
	var firstCharacter: String {
		if let first = name.first {
			return String(first).uppercased()
		}
		return ""
	}
}
