//
//  ChatTopBarView.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import SwiftUI
import XUI
import Services
import Core

struct ChatTopBarView: View {

	@Environment(\.dismiss) private var dismiss
	@Environment(ChatViewManager.self) private var manager

	var body: some View {
		HStack {
			Button {
				dismiss()
			} label: {
				SystemImage(.chevronLeft)
					.bold()
					.imageScale(.large)
					.padding(.init([.top, .bottom, .leading]))
			}
			Spacer()
			VStack(spacing: 0) {
				Text(manager.conversation.name)
					.font(
						.system(
							size: 16,
							weight: .semibold,
							design: .rounded
						)
					).badgeView(Text(manager.config.totalMsgsCount, format: .number).font(.footnote.italic()))
			}
			.onTapGesture {
				Router.shared
					.push(
						NavPath
							.conversationDetails(manager.conversation)
					)
			}
			Spacer()
			AsyncButton {
			} label: {
				SystemImage(.quoteClosing, 18)
					.padding(.init([.top, .bottom, .trailing]))
			}
		}
		.frame(height: ChatLayoutConstants.topBarHeight)
		.background {
			manager.conversation.theme.background.color.ignoresSafeArea(edges: .top)
		}
	}
}
