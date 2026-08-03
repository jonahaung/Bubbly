//  Contact.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Contacts
import Foundation
import PhoneNumberKit

// MARK: - Contact

public struct Contact: ContactRepresentableSendable, Codable, Hashable {
    public var uid: String
    public var name: String
    public let mobile: String
    public var photoURL: String
    public var pushToken: String
    public var publicKeyString: String
}

// MARK: StringMergable

extension Contact: StringMergable {
    public var isChatAvailable: Bool {
        !uid.hasPrefix("+")
    }

    public init?(cnContact: CNContact) {
        let name = cnContact.givenName.isEmpty ? [
            cnContact.middleName,
            cnContact.familyName
        ]
            .joined(
                separator: " "
            )
            .trimmed : cnContact.givenName.trimmed

        guard !name.isWhitespace,
              let phoneNumberString = cnContact.phoneNumbers
                  .first(where: { $0.value.stringValue.isWhitespace == false })?
                  .value
                  .stringValue else
        {
            return nil
        }

        let phoneNumberKit = PhoneNumberKit()
        guard let phoneNumber = try? phoneNumberKit.parse(phoneNumberString),
              phoneNumber.type == .mobile else
        {
            return nil
        }

        let formattedPhoneNumber =
            phoneNumberKit
                .format(phoneNumber, toType: .e164)
                .withoutSpacesAndNewLines

        self.init(
            uid: formattedPhoneNumber,
            name: name,
            mobile: formattedPhoneNumber,
            photoURL: "",
            pushToken: "",
            publicKeyString: ""
        )
    }
}

// MARK: EmptyRepresentable

extension Contact: EmptyRepresentable {
    public static var empty: Contact {
        .init(uid: "", name: "", mobile: "", photoURL: "", pushToken: "", publicKeyString: "")
    }
}
