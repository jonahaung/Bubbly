//
//  ChatTitleBar.swift
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
		HStack {
			AsyncButton(
				options: [
					.disallowParallelOperations,
					.enableTintFeedback,
					.disableButtonOnLoading,
					.disallowParallelOperations
				]
			) {
				await manager.saveConversationChanges()
				dismiss()
			} label: {
				Image(systemSymbol: .chevronBackward)
					.padding()
			}
			.background(theme.backgroundColor)

			Spacer()
			VStack(spacing: 0) {
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
					.push(
						NavPath
							.conversationDetails(manager.conversation)
					)
			}
			Spacer()
			AsyncButton(
				options: [
					.disallowParallelOperations,
					.enableTintFeedback,
					.disableButtonOnLoading,
					.disallowParallelOperations
				]
			) {
				try await Task.sleep(seconds: 1)
			} label: {
				Image(systemSymbol: .quoteClosing)
					.padding()
			}
			.background(theme.backgroundColor)
		}
		.buttonStyle(.plain)
		.background(theme.backgroundColor, ignoresSafeAreaEdges: [.leading, .trailing, .top])
	}
}
