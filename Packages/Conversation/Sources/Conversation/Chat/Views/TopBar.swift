// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct TopBar: View {

    @Environment(\.conversationTheme) private var theme
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
                    let id = manager.state.conversation.members.random()
                    try await AsyncOrderedStream.mapOrdered(inputs: Array(2 ... 200)) { i in
                        let currentUserID = try CurrentUserID.get()
                        let msg = await Message(
                            uid: IDGenerator.shared.make(),
                            senderID: [currentUserID, id].random(),
                            conID: manager.conversationConfig.conID,
                            text: Lorem.random(),
                            date: Date.now
                                .addingTimeInterval(-(i * [6000, 12000, 6100, 6050, 12050].randomElement()!)
                                    .double),
                            deliveryStatus: .delivered,
                            attachments: [],
                            reactions: [],
                        )
                        try await Store.shared.msgStore?.insert(msg)
                    }

                    @Sendable func randomDateInCurrentWeek() -> Date? {
                        let calendar = Calendar.current
                        let now = Date()
                        guard let weekInterval = calendar.dateInterval(of: .weekOfYear, for: now) else {
                            return nil
                        }

                        let start = weekInterval.start
                        let end = weekInterval.end
                        let randomTime = TimeInterval
                            .random(in: start.timeIntervalSince1970 ... end.timeIntervalSince1970)

                        return Date(timeIntervalSince1970: randomTime)
                    }
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
