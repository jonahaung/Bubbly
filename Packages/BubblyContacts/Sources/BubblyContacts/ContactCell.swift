// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ContactCell: View {
    let contact: Contact
    var onTap: (() async throws -> Void)?

    public init(_ contact: Contact, onTap: (() async throws -> Void)? = nil) {
        self.contact = contact
        self.onTap = onTap
    }

    public var body: some View {
        Label {
            LabeledContent {
                Text(contact.uid == currentUserID ? "You" : "")
                    .font(.footnote)
                    .foregroundStyle(Color.tertiaryText)
                    .italic()
            } label: {
                AsyncButton {
                    try await onTap?()
                } label: {
                    Text(contact.name)
                }
                .tint(Color.primaryText)
            }
        } icon: {
            ProfilePhoto(contact, size: .custom(25))
        }
        .labelIconToTitleSpacing(Spacing.lg)
    }
}
