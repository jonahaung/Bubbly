//  ContactListSectionBuilder.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Database
import Foundation

enum ContactListSectionBuilder {
    static func sections(
        from contacts: [Contact],
        matching searchText: String
    ) -> [ContactListSection] {
        let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        let filteredContacts = query.isEmpty
            ? contacts
            : contacts.filter {
                $0.name.localizedStandardContains(query)
                    || $0.mobile.localizedStandardContains(query)
            }

        return Dictionary(grouping: filteredContacts, by: sectionID)
            .map {
                ContactListSection(
                    id: $0.key,
                    contacts: $0.value.sorted(by: areInAscendingOrder)
                )
            }
            .sorted {
                $0.id.localizedStandardCompare($1.id) == .orderedAscending
            }
    }

    private static func sectionID(for contact: Contact) -> String {
        guard let character = contact.name.first else {
            return "#"
        }
        let value = String(character).uppercased()
        return value.rangeOfCharacter(from: .letters) == nil ? "#" : value
    }

    private static func areInAscendingOrder(
        _ lhs: Contact,
        _ rhs: Contact
    ) -> Bool {
        let comparison = lhs.name.localizedStandardCompare(rhs.name)
        if comparison == .orderedSame {
            return lhs.uid < rhs.uid
        }
        return comparison == .orderedAscending
    }
}
