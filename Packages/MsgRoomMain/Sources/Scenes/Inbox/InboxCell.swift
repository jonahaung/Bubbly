//
//  InboxCell.swift
//  Bubbly
//
//  Created by Aung Ko Min on 4/6/25.
//

import Database
import Services
import SwiftUI
import XUI

struct InboxCell: View {

	let item: InboxItem

	var body: some View {
		HStack {
			ProfilePhoto(item, size: .custom(45))
			Button {
				ConversationInitializer.start(conversation: item.conversation)
			} label: {
				VStack(alignment: .leading) {
					Text(item.title)
						.font(.headline)
						.frame(maxWidth: .infinity, alignment: .leading)
					Text(.init(item.msg.text))
						.font(
							Font
								.system(
									size: 14,
									weight: item.msg.incomingStatus != .read && item.msg.receiptType == .receive
									? .medium
									: .regular
								)
						)
						.foregroundStyle(
							item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .primary : .secondary
						)
						.frame(maxWidth: .infinity, alignment: .leading)
				}
				.lineLimit(4)
				.multilineTextAlignment(.leading)
			}
			.buttonStyle(.borderless)
			.foregroundStyle(.primary)
		}
		.equatable(by: item.msg)
	}
}
