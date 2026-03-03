//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Services
import SwiftUI
import XUI

struct ChatTitleBar: View {
    @Environment(ChatViewManager.self) private var manager
    @Environment(\.conversationTheme) private var theme
    @Environment(\.dismiss) private var dismiss
    var body: some View {

        ZStack(alignment: .top) {
            HStack {
                switch manager.conversation.kind {
                case let .contact(contact):
                    ProfilePhoto(contact, size: .custom(30))
                case let .group(group):
                    ProfilePhoto(group, size: .custom(30))
                }
                Text(manager.conversation.name)
                    .font(
                        .system(
                            size: 14,
                            weight: .semibold,
                            design: .default
                        )
                    ).badgeView(
                        Text(
                            manager.conversationConfig.totalMsgsCount,
                            format: .number
                        ).font(
                            .caption.italic().width(.compressed).weight(.semibold)
                        )
                    )
            }
            .onTapGesture {
                Router.shared.pushToNav(.conversationDetails(manager.conversation))
            }
            HStack(alignment: .top) {
                AsyncButton {
                    dismiss()
                } label: {
                    Image(systemSymbol: .chevronBackward)
                }
                .frame(square: 44)
                .background(.background, in: .circle)

                Spacer()

                AsyncButton {} label: {
                    Image(systemSymbol: .quoteClosing)
                }
                .frame(square: 44)
                .background(.background, in: .circle)
            }
            .padding(.horizontal, 8)
            .padding(.bottom, 8)
        }
        .background(
            LinearGradient(
                colors: [theme.backgroundColor, theme.backgroundColor, .clear],
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .equatable(by: manager.conversation)
    }
}
