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
	@Environment(\.typography) private var typography

	var body: some View {
		Label {
			AsyncButton(options: [.disableButtonOnLoading, .enableTintFeedback]) {
				try await ConversationInitializer.start(conversation: item.conversation)
			} label: { _ in
				LabeledContent {
					if item.msg.incomingStatus != .read && item.msg.receiptType == .receive {
						SystemImage(.circleFill, 10)
							.foregroundStyle(Color.blue)
					}
				} label: {
					Text(item.title)
						.font(typography.headLine)
					Text(item.msg.displayText)
						.font(typography.callout)
						.foregroundStyle(
							item.msg.incomingStatus != .read && item.msg.receiptType == .receive ? .primary : .secondary
						)
				}
			}
			.foregroundStyle(.primary)
		} icon: {
			ProfilePhoto(item, size: .custom(45))
				.padding(.leading)
		}
		.labelIconToTitleSpacing(30)
		.multilineTextAlignment(.leading)
		.equatable(by: item.msg)
	}
}
