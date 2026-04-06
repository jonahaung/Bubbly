//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI

public struct ContactDetailsScene: View {
    let contact: Contact
    public init(contact: Contact, coordinator: AppCoordinator) {
        self.contact = contact
    }

    public var body: some View {
        Form {
            Section {
                Text(contact.preetyPrinted)
            } header: {
                ProfilePhoto(contact, size: .original)
            }
        }
    }
}
