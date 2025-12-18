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
		VStack {
			Text(manager.conversation.name)
				.bold()
			Text(.init(manager.conversation.preetyPrinted))
				.font(.footnote)
		}
		.flexible(.horizontal)
		.padding()
		.background(
			Color.secondarySystemGroupedBackground,
			in: RoundedRectangle(
				cornerRadius: 12
			)
		)
		.lineHeight(.leading(increase: 0))
		.lineSpacing(0)
		.baselineOffset(0)
        .padding(.horizontal)
		.allowsTightening(true)
        .id(Self.typeName)
        .layoutValue(.init(uid: Self.typeName, recipient: .none))
    }
}
