//
//  InboxCell.swift
//  Bubbly
//
//  Created by Aung Ko Min on 4/6/25.
//

import SwiftUI
import Services
import XUI
import MsgRoomMain
import Database

struct InboxCell: View {

	let item: InboxItem

	var body: some View {
		Button {
			ConversationInitializer
				.start(conID: item.conversation.uid, refetch: false)
		} label: {
			HStack {
				ProfilePhoto(item, size: .custom(50))
				VStack(alignment: .leading) {
					HStack {
						Text(item.title).bold()
						Spacer()
					}
					Text(item.sender.name + " ")
						.font(.footnote.lowercaseSmallCaps())
						.foregroundStyle(.secondary)
					+
					Text(item.msg.text)
						.font(
							Font
								.system(
									size: 14,
									weight: item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .medium
									: .regular)
						)
						.foregroundStyle(
							item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .primary : .secondary
						)

				}
				.lineLimit(3)

				Spacer()
			}
			.flexible(.horizontal)
		}
		.foregroundStyle(Color.primary)
		.transition(.identity)
	}
}
