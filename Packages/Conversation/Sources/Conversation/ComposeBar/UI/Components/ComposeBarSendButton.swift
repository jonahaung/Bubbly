import Database
import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarSendButton: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(ChatViewManager.self) private var manager

		var body: some View {
			AsyncButton {
				if composer.hasContent {
					composer.send(conversation: manager.conversation)
				} else {
					composer.inputText.text = Lorem.random()
				}
			} label: {
				ZStack {
					Image(systemName: "paperplane")
						.resizable()
						.scaledToFit()
						.frame(square: 24)

					if composer.isLoading {
						LoadingIndicator(43)
							.opacity(0.5)
					}
				}
				.frame(width: 44, height: 44, alignment: .center)
				.background(.windowBackground, in: .circle)
				.symbolVariant(composer.inputText.hasText ? .fill : .none)
			}
		}
	}
}
