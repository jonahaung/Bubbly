// © 2026 Aung Ko Min

import Contacts
import Database
import Foundation
@preconcurrency import PhoneNumberKit
import XUI

public enum ContactError: Error {
    case permissionDenied
}

public actor PhoneContactsService {
    public static let shared: PhoneContactsService = .init()

	private let store = CNContactStore()

	public init() {}

	public func fetchContacts() async throws -> [Contact] {
		try await requestAccess()

		let keys: [CNKeyDescriptor] = [
			CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
			CNContactPhoneNumbersKey as CNKeyDescriptor,
			CNContactThumbnailImageDataKey as CNKeyDescriptor
		]

		var seen = Set<String>()
		var results: [Contact] = []

		let request = CNContactFetchRequest(keysToFetch: keys)

		try store.enumerateContacts(with: request) { phoneContact, _ in
			guard let contact = Contact(cnContact: phoneContact),
				  seen.insert(contact.mobile).inserted
			else { return }

			results.append(contact)
		}

		return results
	}

	private func requestAccess() async throws {
		try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
			store.requestAccess(for: .contacts) { granted, error in
				if let error {
					cont.resume(throwing: error)
					return
				}
				guard granted else {
					cont.resume(throwing: ContactError.permissionDenied)
					return
				}
				cont.resume(returning: ())
			}
		}
	}
    @discardableResult
    @concurrent
    public func syncContacts() async throws -> [Contact] {
		let phoneContacts = try await fetchContacts()
        let phoneNumberKit = PhoneNumberKit()
        let dbContact = await Store.shared.contactStore
        let normalizedContacts = try phoneContacts.map { phoneContact in
            let parsedNumber = try phoneNumberKit.parse(phoneContact.mobile)
            let formattedNumber = phoneNumberKit.format(parsedNumber, toType: .e164)
            return (phoneContact, formattedNumber)
        }
        let remoteContacts = try await BackendAPIClient.shared.lookupContacts(
            mobileNumbers: normalizedContacts.map(\.1)
        )
        let contactsByMobile = Dictionary(uniqueKeysWithValues: remoteContacts.map { ($0.mobile, $0) })
        var contacts: [Contact] = []
        contacts.reserveCapacity(normalizedContacts.count)
        for (phoneContact, mobile) in normalizedContacts {
            guard var remoteContact = contactsByMobile[mobile] else {
                continue
            }
            remoteContact.name = phoneContact.name
            try await dbContact?.insert(remoteContact)
            contacts.append(remoteContact)
        }
        return contacts
    }
}
