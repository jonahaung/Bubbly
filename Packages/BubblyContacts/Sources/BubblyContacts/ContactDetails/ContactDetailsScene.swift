//  ContactDetailsScene.swift
//
//  Copyright © 2025 Aung Ko Min.
//

import Shared
import SwiftUI
import Database
import Services

public struct ContactDetailsScene: View {
    let contact: Contact
    public init(contact: Contact, coordinator _: AppCoordinator) {
        self.contact = contact
    }

    public var body: some View {
        Form {
            Section {
                Text(contact.prettyPrinted)
            } header: {
                ProfilePhoto(contact, size: .original)
            }
        }
    }
}
