//  Contact++.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import XUI
import Core
import Shared
import Contacts
import Foundation
import PhoneNumberKit

extension Contact: @retroactive Identifiable {}
extension Contact: UIdentifiable {}

public extension Contact {
    var isChatAvailable: Bool {
        !uid.hasPrefix("+")
    }

    init?(cnContact: CNContact) {
        let name =
            cnContact.givenName.isEmpty
            ? [
                cnContact.middleName,
                cnContact.familyName,
            ]
            .joined(
                separator: " "
            )
            .trimmed : cnContact.givenName.trimmed

        guard !name.isWhitespace,
            let phoneNumberString = cnContact.phoneNumbers
                .first(where: { $0.value.stringValue.isWhitespace == false })?
                .value
                .stringValue
        else {
            return nil
        }

        let phoneNumberKit = PhoneNumberUtility()
        guard let phoneNumber = try? phoneNumberKit.parse(phoneNumberString),
            phoneNumber.type == .mobile
        else {
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

extension Contact: @retroactive EmptyRepresentable {
    public static var empty: Contact {
        .init(uid: "", name: "", mobile: "", photoURL: "", pushToken: "", publicKeyString: "")
    }
}
