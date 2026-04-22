// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

public struct ContactCell: View {
    let contact: Contact
    var onTap: (() async throws -> Void)?
    @Environment(\.currentUser) private var currentUser

    public init(_ contact: Contact, onTap: (() async throws -> Void)? = nil) {
        self.contact = contact
        self.onTap = onTap
    }

    public var body: some View {
        AsyncButton {
            try await onTap?()
        } label: {
            Label {
                LabeledContent {
                    Text(contact.uid == currentUser.uid ? "You" : "")
                        .font(.footnote)
                        .foregroundStyle(Color.tertiaryText)
                        .italic()
                } label: {
                    Text(contact.name)
                }
            } icon: {
                ProfilePhoto(contact, size: .custom(25))
            }
            .labelIconToTitleSpacing(Spacing.lg)
        }
        .padding(.horizontal, Padding.sm)
        .equatable(by: contact)
        .id(contact.id)
    }
}
