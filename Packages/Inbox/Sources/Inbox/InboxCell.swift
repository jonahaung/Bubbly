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
	@Environment(\.openURL) private var openURL

    var body: some View {
		CustomButton {
			Router.shared.setTabBar(visibility: .hidden)
		} label: {
			Label {
				Text(item.title)
					.font(typography.headLine)
				Text(item.msg.displayText)
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
		} onFinished: {
			if let url = DeepLinkCoordinator()
				.url(for: .conversation(id: item.conversation.uid)) {
				openURL(url)
			}
		}
        .equatable(by: item.msg)
    }
}
