// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct TopBar: View {

    @Environment(\.conversationTheme) private var theme
    private let mockMessageCreator = MockMessageCreator()

    var body: some View {
        ZStack(alignment: .top) {
            CustomButton {
                UIApplication.shared.endEditing()
            } label: {
                Text(manager.state.conversation.name)
                    .font(.system(size: UIFont.systemFontSize + 1, weight: .semibold))
                    .badgeView(
                        Text(
                            manager.conversationConfig.totalMsgsCount,
                            format: .number,
                        )
                        .font(.system(size: UIFont.smallSystemFontSize, weight: .medium).width(.compressed))
                        .lineHeight(.multiple(factor: 1.2))
                        .textScale(.secondary),
                    )
                    .background(theme.backgroundColor)
            } onFinished: {
                manager.router?.pushToNav(.conversationDetails(manager.state.conversation))
            }
            HStack(alignment: .top) {
                CustomButton {
                    manager.router?.pop()
                } label: {
                    Image(systemSymbol: .chevronBackward)
                        .frame(square: 44)
                        .background(Color.appPrimary, in: .circle)
                }
                Spacer()

                AsyncButton {
                    try await mockMessageCreator.createTextMessages(count: 1,
                                                                     in: manager.state.conversation, direction: .incoming
                    )
                } label: {
                    switch manager.state.conversation.kind {
                    case let .contact(contact):
                        ProfilePhoto(
                            contact,
                            size: .custom(32), tapAction: .none
                        )
                    case let .group(group):
                        ProfilePhoto(
                            group,
                            size: .custom(32), tapAction: .none
                        )
                    }
                }
            }
            .padding(.horizontal, Padding.sm)
        }
        .background(
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.backgroundColor,
                    theme.backgroundColor.opacity(0.5)
                ],
                startPoint: .top,
                endPoint: .bottom,
            ),
        )
        .geometryGroup()
        .equatable(by: manager.conversationConfig.conID)
    }

    @Environment(ChatManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
}
