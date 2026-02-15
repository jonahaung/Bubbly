import Contacts
import Database
import Foundation
@preconcurrency import PhoneNumberKit
import XUI

public final class PhoneContactsService {
	nonisolated(unsafe) public static let shared = PhoneContactsService()

	private var isSyncing = false

	public func fetchContacts() async throws -> [Contact] {
		let contactStore = CNContactStore()
		let keysToFetch: [CNKeyDescriptor] = [
			CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
			CNContactPhoneNumbersKey as CNKeyDescriptor,
			CNContactThumbnailImageDataKey as CNKeyDescriptor,
		]

		let allContainers = try contactStore.containers(matching: nil)
		var results: [CNContact] = []

		for container in allContainers {
			let fetchPredicate = CNContact.predicateForContactsInContainer(
				withIdentifier: container.identifier
			)
			let containerResults = try contactStore.unifiedContacts(
				matching: fetchPredicate,
				keysToFetch: keysToFetch
			)
			results.append(contentsOf: containerResults)
		}

		var seenMobiles = Set<String>()
		let mapped = results.compactMap { Contact(cnContact: $0) }
		return mapped.filter { contact in
			guard !contact.mobile.isEmpty else { return false }
			return seenMobiles.insert(contact.mobile).inserted
		}
	}

	@discardableResult
	@concurrent
	public func syncContacts() async throws -> [Contact] {
		let phoneContacts = try await fetchContacts()
		let phoneNumberKit = PhoneNumberKit()
		let dbContact = await Store.shared.contactStore
		let contacts: [Contact?] = try await AsyncOrderedStream
			.mapOrdered(inputs: phoneContacts) { phoneContact in
				let parsedNumber = try phoneNumberKit.parse(phoneContact.mobile)
				let formattedNumber = phoneNumberKit.format(parsedNumber, toType: .e164)
				let remoteContact: Contact? = try await FirestoreRepo.getModel(
					for: formattedNumber,
					collection: .users,
					field: .mobile
				)
				if var remoteContact {
					remoteContact.name = phoneContact.name
					try await dbContact?.insert(remoteContact)
					return remoteContact
				} else {
					return nil
				}
			}
		return contacts.compactMap(\.self)
	}
}
