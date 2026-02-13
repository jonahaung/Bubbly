import PhotosUI
import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarMenuButton: View {
		@Environment(ChatComposer.self) private var composer: ChatComposer
		@Environment(ConversationViewModel.self) private var viewModel
		@Environment(\.sharedFocusState) private var sharedFocus

		var body: some View {
			AsyncButton {
				let isMenu = composer.source == .menu
				await viewModel.send(.updateComposerSource(isMenu ? .text : .menu))
			} label: {
				TwoLinesShape()
					.frame(square: 24)
					.frame(square: 44)
					.background(
						.windowBackground,
						in: RoundedRectangle(cornerRadius: 22, style: .circular)
					)
			}
			.buttonStyle(.plain)
		}
	}
}
