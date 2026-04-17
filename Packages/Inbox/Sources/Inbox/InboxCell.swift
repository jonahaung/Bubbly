// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI
import XUI
import Core

struct InboxCell: View {
    let item: InboxItem
    let onSelect: (InboxItem) -> Void

    @Environment(\.typography) private var typography

    var body: some View {
        Button {
            onSelect(item)
        } label: {
            HStack(spacing: Spacing.md) {
                ProfilePhoto(item, size: .custom(50))
                LabeledContent {
                    if item.unreadMsgsCount > 0 {
                        Image(systemName: "\(item.unreadMsgsCount).circle.fill")
                            .foregroundStyle(Color.blue)
                            .imageScale(.small)
                    }
                } label: {
                    Text(item.title)
                        .font(.headline)
                    Text(.init(item.msg.displayText))
                        .font(.system(size: UIFont.labelFontSize))
                        .lineHeight(.multiple(factor: 1.1))
                        .lineLimit(5)
                        .foregroundStyle(
                            item.unreadMsgsCount == 0 ? Color.quaternaryText : .primaryText,
                        )
                        .multilineTextAlignment(.leading)
                }
            }
        }
        .equatable(by: item.msg)
    }
}
