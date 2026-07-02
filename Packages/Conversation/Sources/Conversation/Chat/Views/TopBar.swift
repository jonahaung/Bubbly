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

    var body: some View {
        ZStack(alignment: .center) {
            CustomButton {
                UIApplication.shared.endEditing()
            } label: {
                Text(manager.state.conversation.name)
                    .font(.system(size: UIFont.systemFontSize + 1, weight: .semibold))
                    .badgeView(
                        Text(
                            manager.messages.pagination.totalMsgsCount,
                            format: .number
                        )
                        .font(.system(size: UIFont.smallSystemFontSize, weight: .medium).width(.compressed))
                        .lineHeight(.multiple(factor: 1.2))
                        .textScale(.secondary)
                    )
                    .padding(Padding.sm)
                    .background(theme.backgroundColor)
            } onFinished: {
                Task { @MainActor in
                    manager.router?.pushToNav(.conversationDetails(manager.state.conversation))
                }
            }
            HStack(alignment: .top) {
                AsyncButton {
                    try await manager.prepareToExit()
                } label: {
                    Image(systemSymbol: .chevronBackward)
                        .frame(square: 44)
                        .background(Color.appPrimary, in: .circle)
                }
                Spacer()
                AsyncButton {
                    var msg = try await MsgCreator().message(text: Lorem.random(), attachments: [], in: manager.state.conversation)
                    msg.senderID = manager.state.conversation.members.random()
                    try await Socket.shared.send(.newMsg(rMsg: .init(msg)))
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
        .equatable(by: manager.messages.pagination.conID)
    }

    @Environment(ChatManager.self) private var manager
    @Environment(\.dismiss) private var dismiss
}
