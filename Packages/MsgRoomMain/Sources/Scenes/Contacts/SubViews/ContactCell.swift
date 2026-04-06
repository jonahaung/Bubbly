//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct ContactCell: View {
    let contact: Contact
    var onTap: (() async throws -> Void)?

    init(_ contact: Contact, onTap: (() async throws -> Void)? = nil) {
        self.contact = contact
        self.onTap = onTap
    }

    var body: some View {
        Label {
            LabeledContent {
                SystemImage(.arrowUpRightCircleFill)
                    .presentSheet {
                        MsgSenderInputSheet(conversationName: contact.name)
                    }
            } label: {
                AsyncButton {
                    try await onTap?()
                } label: {
                    Text(contact.name)
                }
                .buttonStyle(.borderless)
                .foregroundStyle(.primary)
            }
        } icon: {
            ProfilePhoto(contact, size: .custom(25))
        }
    }

    private var isEnabled: Bool {
        contact.isChatAvailable && contact.uid != currentUserID
    }
}
