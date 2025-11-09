//
//  InboxCell.swift
//  Bubbly
//
//  Created by Aung Ko Min on 4/6/25.
//

import Database
import MsgRoomMain
import Services
import SwiftUI
import XUI

struct InboxCell: View {
    let item: InboxItem

    var body: some View {
        HStack {
            ProfilePhoto(item, size: .custom(50))
                .equatable(by: item.conversation.uid)
            VStack(alignment: .leading) {
                HStack {
                    Text(item.title).bold()
                    Spacer()
                }
                Text("\(item.sender.name) ")
                    .font(.footnote.lowercaseSmallCaps())
                    .foregroundStyle(.secondary)
                    +
                    Text(item.msg.text)
                    .font(
                        Font
                            .system(
                                size: 14,
                                weight: item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .medium
                                    : .regular
                            )
                    )
                    .foregroundStyle(
                        item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .primary : .secondary
                    )
            }
            .lineLimit(3)

            Spacer()
        }
        .flexible(.horizontal)
        .background()
        .onTapGesture {
            ConversationInitializer.start(conversation: item.conversation)
        }
    }
}
