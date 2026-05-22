// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct SelectableContactCell: View {
    let contact: Contact
    let isSelected: Bool
    let onSelected: (Bool) -> Void

    var body: some View {
        Button {
            onSelected(!isSelected)
        } label: {
            Label {
                LabeledContent {
                    Text(
                        "\(Image(systemName: isSelected ? "checkmark.circle.fill" : "circle"))"
                    )
                } label: {
                    Text(contact.name)
                }
            } icon: {
                ProfilePhoto(contact, size: .mini)
            }
            .labelIconToTitleSpacing(Spacing.md)
        }
        .buttonStyle(.borderless)
    }
}
