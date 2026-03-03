//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI
import XUI

struct InboxCell: View {
    let item: InboxItem
    @Environment(\.typography) private var typography

    var body: some View {
        Button {
            if let url = DeepLinkCoordinator.shared
                .url(for: .conversation(id: item.conversation.uid)) {
                UIApplication.shared.open(url)
            }
        } label: {
            Label {
                Text(item.title)
                    .font(typography.headLine)
                Text(.init(item.msg.displayText))
                    .font(typography.subHeadline)
                    .lineLimit(3)
                    .foregroundStyle(
                        item.unreadMsgsCount == 0 ? .secondary : .primary
                    )
                    .multilineTextAlignment(.leading)
            } icon: {
                ProfilePhoto(item, size: .custom(50))
            }
            .badge(item.unreadMsgsCount)
            .badgeProminence(.increased)
            .labelReservedIconWidth(45)
        }
        .buttonStyle(.borderless)
        .foregroundStyle(.primary)
        .equatable(by: item.msg)
    }
}
