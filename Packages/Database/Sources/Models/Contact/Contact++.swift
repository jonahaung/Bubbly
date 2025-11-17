//
//  Contact++.swift
//  Database
//
//  Created by Aung Ko Min on 2/11/25.
//

import Contacts
import Foundation
import PhoneNumberKit
import XUI

public protocol StringMergable {}
public extension StringMergable {
    func mergedString(current: String, incoming: String) -> String {
        let trimmed = incoming.trimmingCharacters(in: .whitespacesAndNewlines)
        return trimmed.isEmpty ? current : trimmed
    }
}

public extension PContact {
    typealias SendableType = Contact
    convenience init(from item: Contact) {
        self.init(
            uid: item.id,
            name: item.name,
            mobile: item.mobile,
            photoURL: item.photoURL,
            pushToken: item.pushToken,
            publicKeyString: item.publicKeyString,
            theme: item.theme,
            seenMember: item.seenMember,
            lastMsgID: item.lastMsgID
        )
    }

    func toSendable() -> Contact {
        Contact(
            uid: uid,
            name: name,
            photoURL: photoURL,
            pushToken: pushToken,
            publicKeyString: publicKeyString,
            mobile: mobile,
            theme: theme,
            seenMember: seenMember,
            lastMsgID: lastMsgID
        )
    }
}

extension PContact: StringMergable {
    public func merge(from source: Contact) {
        guard source.uid == uid else { return }
        name = mergedString(current: name, incoming: source.name)
        photoURL = mergedString(current: photoURL, incoming: source.photoURL)
        pushToken = mergedString(current: pushToken, incoming: source.pushToken)
        publicKeyString = mergedString(current: publicKeyString, incoming: source.publicKeyString)
        lastMsgID = source.lastMsgID ?? lastMsgID
        theme = source.theme
        seenMember = source.seenMember ?? seenMember
    }

    public func update(with source: Contact) {
        merge(from: source)
    }

    public func update(with item: any ConversationRepresentable) {
        name = mergedString(current: name, incoming: item.name)
        photoURL = mergedString(current: photoURL, incoming: item.photoURL)
        lastMsgID = item.lastMsgID ?? lastMsgID
        theme = item.theme
        seenMember = item.seenMembers.first ?? seenMember
    }
}

public extension Contact {
    init(_ item: RContact) {
        self.init(
            uid: item.uid,
            name: item.name,
            photoURL: item.photoURL,
            pushToken: item.pushToken,
            publicKeyString: item.publicKeyString,
            mobile: item.mobile,
            theme: .init(),
            seenMember: nil,
            lastMsgID: nil
        )
    }

    init?(cnContact: CNContact) {
        let name =
            cnContact.givenName.isEmpty
                ? [cnContact.middleName, cnContact.familyName].joined(separator: " ").trimmed
                : cnContact.givenName.trimmed

        guard !name.isWhitespace,
              let phoneNumberString = cnContact.phoneNumbers.first(where: { $0.value.stringValue.isWhitespace == false })?.value.stringValue
        else {
            return nil
        }

        let phoneNumberKit = PhoneNumberKit()
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
            photoURL: "",
            pushToken: "",
            publicKeyString: "",
            mobile: formattedPhoneNumber,
            theme: .init(),
            seenMember: nil,
            lastMsgID: nil
        )
    }
}

extension Contact: StringMergable {
    public func merging(from source: Contact) -> Contact {
        guard source.uid == uid else { return self }
        var copy = self
        copy.name = mergedString(current: copy.name, incoming: source.name)
        copy.photoURL = mergedString(current: copy.photoURL, incoming: source.photoURL)
        copy.pushToken = mergedString(current: copy.pushToken, incoming: source.pushToken)
        copy.publicKeyString = mergedString(current: copy.publicKeyString, incoming: source.publicKeyString)
        copy.lastMsgID = source.lastMsgID ?? copy.lastMsgID
        copy.theme = source.theme
        copy.seenMember = source.seenMember ?? copy.seenMember
        return copy
    }

    public func merging(from item: any ConversationRepresentable) -> Contact {
        var copy = self
        copy.name = mergedString(current: copy.name, incoming: item.name)
        copy.photoURL = mergedString(current: copy.photoURL, incoming: item.photoURL)
        copy.lastMsgID = item.lastMsgID ?? copy.lastMsgID
        copy.theme = item.theme
        copy.seenMember = item.seenMembers.first ?? copy.seenMember
        return copy
    }
}
