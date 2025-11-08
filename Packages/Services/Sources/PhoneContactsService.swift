//
//  PhoneContacts.swift
//  MsgRoom
//
//  Created by Aung Ko Min on 27/6/24.
//

import Foundation
import Contacts
import Database
import XUI
@preconcurrency import PhoneNumberKit

public final class PhoneContactsService {

	nonisolated(unsafe) public static let shared = PhoneContactsService()

	private var isSyncing = false

	public func fetchContacts() async throws -> [Contact] {
		let contactStore = CNContactStore()
		let keysToFetch: [CNKeyDescriptor] = [
			CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
			CNContactPhoneNumbersKey as CNKeyDescriptor,
			CNContactThumbnailImageDataKey as CNKeyDescriptor
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

		let contacts = results
			.compactMap { Contact(cnContact: $0) }
			.removeDuplicates { $0.mobile == $1.mobile }

		return contacts
	}

	@discardableResult
	@concurrent
	public func syncContacts() async throws -> sending [Contact] {
		let phoneContacts = try await fetchContacts()
		let phoneNumberKit = PhoneNumberKit()
		let dbContact = Store.shared.contactStore
		let contacts: [Contact?] = try await AsyncOrderedStream.mapOrdered(inputs: phoneContacts) { phoneContact in
			let parsedNumber = try phoneNumberKit.parse(phoneContact.mobile)
			let formattedNumber = phoneNumberKit.format(parsedNumber, toType: .e164)
			let remoteContact: Contact? = try await FirestoreRepo.getModel(
				for: formattedNumber,
				collection: .users,
				field: .mobile
			)
			if var remoteContact {
				remoteContact.name = phoneContact.name
				try await dbContact.insert(remoteContact)
				return remoteContact
			} else {
				return nil
			}
		}
		return contacts.compactMap { $0 }
	}
}
