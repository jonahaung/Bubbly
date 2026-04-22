//  TopBar.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct TopBar: View {

    @Environment(\.conversationTheme) private var theme
    private let mockMessageCreator: MockMessageCreator = .init()

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
                            format: .number
                        )
                        .font(.system(size: UIFont.smallSystemFontSize, weight: .medium).width(.compressed))
                        .lineHeight(.multiple(factor: 1.2))
                        .textScale(.secondary)
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
                CustomButton {
                    Task {try await mockMessageCreator.createTextMessages(count: 1,
                                                                          in: manager.state.conversation, direction: .incoming)}
                } label: {
                    Image(systemSymbol: .quoteClosing)
                        .frame(square: 44)
                        .background(Color.appPrimary, in: .circle)
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
                endPoint: .bottom
            )
        )
        .geometryGroup()
        .equatable(by: manager.conversationConfig.conID)
    }

    @Environment(ChatManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
}
