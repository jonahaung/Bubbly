#if os(iOS)
import Database
import SwiftUI
import XUI
import Core

extension ComposeBar {
	struct ComposeBarSendButton: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(ChatManager.self) private var manager

		var body: some View {
			AsyncButton {
				if composer.hasContent {
					withTransaction(.withoutAnimation()) {
						composer.send(conversation: manager.state.conversation)
					}
				} else {
					composer.inputText.text = Lorem.random()
				}
			} label: {
				ZStack {
					let hasText = composer.inputText.hasText
					Image(systemName: "paperplane.fill")
						.resizable()
						.scaledToFit()
						.frame(square: 24)
						.foregroundStyle(hasText ? .primary : .secondary)
						.padding()
						.rotationEffect(
							.degrees(hasText ? -45 : -180),
							anchor: .center
						)
						.animation(.anticipateOvershoot, value: hasText)
				}
				.frame(width: ChatLayoutConstants.bottomBarHeight, height: ChatLayoutConstants.bottomBarHeight, alignment: .center)
				.background(.windowBackground, in: .circle)
				.geometryGroup()
			}
		}
	}
}

#endif
