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
    let conversationManager = ConversationManager()

    var body: some View {
        ZStack(alignment: .center) {
            CustomButton {
                UIApplication.shared.endEditing()
            } label: {
                Text(manager.state.conversation.name)
                    .font(.headline)
                    .badgeView(
                        Text(
                            manager.messages.pagination.totalMsgsCount,
                            format: .number
                        )
                        .font(.caption)
                        .fontWidth(.compressed)
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
                .accessibilityLabel("Close conversation")
                Spacer()
                AsyncButton {
                    if let msg = manager.messages.last {
                        try await generateResponses(
                            for: msg.msg,
                            in: manager.state.conversation
                        )
                    }
                } label: {
                    Image(systemSymbol: .quoteClosing)
                        .frame(square: 44)
                        .background(Color.appPrimary, in: .circle)
                }
                .accessibilityLabel("Send sample message")
            }
            .padding(.horizontal, Padding.sm)
        }
        .background(
            LinearGradient(
                colors: [
                    theme.backgroundColor,
                    theme.backgroundColor,
                    theme.backgroundColor.opacity(0.5),
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

    private func generateResponses(for message: Message, in conversation: Conversation) async throws {
        let messageBody = message.text ?? ""
        let originalMessageID = message.id

        // Extract Sendable snapshots while on the model actor where
        // SwiftData access is safe.
        let currentUserID = try CurrentUserID.get()
        let recipients = manager.members.members
            .filter { $0.uid != currentUserID }
            .map { recipient in
                ConversationManager.RecipientSnapshot(
                    id: recipient.id,
                    name: recipient.name,
                    personality: "Reflective, gentle, sensitive",
                    interests: "Helping others, boat rides, journaling"
                )
            }
        let history = manager.messages.wrappedValue.map { $0.msg }
            .filter { $0.id != originalMessageID }
            .map { message in
                let sender = manager.members.contact(for: message.senderID)
                return ConversationManager.MessageSnapshot(
                    authorName: sender?.name ?? "Unknown",
                    body: message.text ?? ""
                )
            }

        // Drain the stream on this actor. Language model work runs off-actor in the
        // producer task; each yielded response persists in order on the model actor.
        let stream = conversationManager.responses(
            for: messageBody,
            recipients: recipients,
            history: history
        )
        for await response in stream {
            var msg = try await MsgCreator().message(
                text: response.text,
                attachments: [],
                in: manager.state.conversation
            )
            msg.senderID = manager.state.conversation.members.random()
            try await Socket.shared.send(.newMsg(rMsg: .init(msg)))
        }
    }
}
