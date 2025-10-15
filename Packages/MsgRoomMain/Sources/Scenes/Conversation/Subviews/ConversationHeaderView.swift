//
//  ChatHeaderView.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 12/7/25.
//

import SwiftUI
import Database
import Services
import XUI
import Core

struct ConversationHeaderView: View {

	@Environment(ChatViewManager.self) private var manager
	
	var body: some View {
		ZStack {
			RoundedRectangle(cornerRadius: 12)
				.fill(Color.secondarySystemGroupedBackground)
			VStack(alignment: .center) {
				ProfilePhoto(
					manager.conversation,
					size: .original
				)
				.frame(square: 250)
				VStack(alignment: .leading) {
					Text(Self.typeName)
					Text(
						manager.conversation
							.name)
					.font(.headline)
					Text(manager.conversation.preetyPrinted)
						.font(.footnote)
				}
			}
			.padding()
		}
		.id(Self.typeName)
		.layoutValue(.init(uid: Self.typeName, recipient: .none))
	}
}
