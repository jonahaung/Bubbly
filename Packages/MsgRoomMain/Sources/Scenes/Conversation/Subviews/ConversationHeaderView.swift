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
		ZStack(alignment: .bottom) {
			VStack {
				Text(manager.conversation.name)
					.bold()
				Group {
					switch manager.conversation.kind {
					case .contact(let contact):
						Text(.init(contact.preetyPrinted))
					case .group(let group):
						Text(.init(group.preetyPrinted))
					case .system(let ai):
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
