//
//  ChatHeaderBar.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import Core
import Services
import SwiftUI
import XUI

struct ChatTitleBar: View {
	@Environment(\.dismiss) private var dismiss
	@Environment(ChatViewManager.self) private var manager
	@Environment(\.conversationTheme) private var theme

	var body: some View {
		ZStack(alignment: .top) {
			HStack {
				switch manager.conversation.kind {
				case let .contact(contact):
					ProfilePhoto(contact, size: .custom(30))
				case let .group(group):
					ProfilePhoto(group, size: .custom(30))
				}
				Text(manager.conversation.name)
					.font(
						.system(
							size: 14,
							weight: .semibold,
							design: .default
						)
					).badgeView(
						Text(
							manager.conversationConfig.totalMsgsCount,
							format: .number
						).font(
							.caption.italic().width(.compressed).weight(.semibold)
						)
					)
			}
			.onTapGesture {
				Router.shared
					.pushToNav(
						NavPath
							.conversationDetails(manager.conversation)
					)
			}
			HStack(alignment: .top) {
				AsyncButton(
					options: [
						.disallowParallelOperations,
						.enableTintFeedback,
						.disableButtonOnLoading,
						.disallowParallelOperations,
					]
				) {
					await manager.saveConversationChanges()
					dismiss()
				} label: {
					Image(systemSymbol: .chevronBackward)
				}
				.frame(square: 44)
				.background(.background, in: .circle)

				Spacer()

				AsyncButton(
					options: [
						.disallowParallelOperations,
						.enableTintFeedback,
						.disableButtonOnLoading,
						.disallowParallelOperations,
					]
				) {
					try await Task.sleep(seconds: 1)
				} label: {
					Image(systemSymbol: .quoteClosing)
				}
				.frame(square: 44)
				.background(.background, in: .circle)
			}
			.padding(.horizontal, 8)
			.padding(.bottom, 8)
		}
		.background(theme.backgroundColor)
	}
}
