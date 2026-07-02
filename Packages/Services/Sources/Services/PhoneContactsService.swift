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

		try store.enumerateContacts(with: request) { cn, _ in
			guard let c = Contact(cnContact: cn),
				  seen.insert(c.mobile).inserted
			else { return }

			results.append(c)
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
        let contacts: [Contact?] = try await AsyncOrderedStream
            .mapOrdered(inputs: phoneContacts) { phoneContact in
                let parsedNumber = try phoneNumberKit.parse(phoneContact.mobile)
                let formattedNumber = phoneNumberKit.format(parsedNumber, toType: .e164)
                let remoteContact: Contact? = try await FirestoreRepo.getModel(
                    for: formattedNumber,
                    collection: .users,
                    field: .mobile,
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
