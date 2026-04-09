// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI

struct InboxCell: View {
    let item: InboxItem
    let onSelect: (InboxItem) -> Void

    @Environment(\.typography) private var typography

    var body: some View {
        CustomButton {
            onSelect(item)
        } label: {
            Label {
                Text(item.title)
                    .font(typography.headLine)
                    .redactable()
                Text(item.msg.displayText)
                    .font(typography.subHeadline)
                    .lineLimit(3)
                    .foregroundStyle(
                        item.unreadMsgsCount == 0 ? .secondary : .primary,
                    )
                    .multilineTextAlignment(.leading)
                    .redactable()
            } icon: {
                ProfilePhoto(item, size: .custom(50))
                    .redactable()
            }
            .badge(item.unreadMsgsCount)
            .badgeProminence(.increased)
            .labelReservedIconWidth(45)
        } onFinished: {}
            .equatable(by: item.msg)
    }
}
