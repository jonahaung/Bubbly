//
//  ConversationHeaderView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct ConversationHeaderView: View {
    @Environment(ChatViewManager.self) private var manager

    var body: some View {
        ZStack(alignment: .bottom) {
            VStack {
                Text(manager.conversation.name)
                    .bold()
                Group {
                    switch manager.conversation.kind {
                    case let .contact(contact):
                        Text(.init(contact.preetyPrinted))
                    case let .group(group):
                        Text(.init(group.preetyPrinted))
                    case let .system(ai):
                        Text(ai.name)
                    }
                }
                .font(.system(.subheadline, design: .serif))
            }
            .flexible(.horizontal)
            .padding()
            .background(
                Color.secondarySystemGroupedBackground,
                in: RoundedRectangle(
                    cornerRadius: 12
                )
            )
        }
        .padding(.horizontal)
        .id(Self.typeName)
        .layoutValue(.init(uid: Self.typeName, recipient: .none))
    }
}
