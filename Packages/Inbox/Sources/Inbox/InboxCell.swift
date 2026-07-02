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
                ProfilePhoto(item, size: .custom(55))
                    .overlay(alignment: .bottomTrailing) {
                        if item.unreadMsgsCount > 0 {
                            Text(item.unreadMsgsCount, format: .number)
                                .padding(.vertical, 2)
                                .padding(.horizontal, 6)
                                .background(.blue.gradient, in: .capsule)
                                .foregroundStyle(Color.container)
                                .font(.system(size: UIFont.smallSystemFontSize-1, weight: .semibold))
                                .lineHeight(.multiple(factor: 1.2))
                        }
                    }
                VStack(alignment: .leading, spacing: 0) {
                    Text(item.title)
                        .font(typography.headLine)
                    
                    Text(item.msg.displayText)
                        .font(typography.subHeadline)
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
