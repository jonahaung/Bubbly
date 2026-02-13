import SwiftUI
import XUI

extension ComposeBar {
	struct ComposeBarSourceButton: View {
		let source: ChatComposer.Source
		@Environment(ConversationViewModel.self) private var viewModel
		
		var body: some View {
			AsyncButton(action: action) {
				Image(systemName: source.systemImageName)
					.resizable()
					.frame(square: 20)
					.foregroundStyle(source.foreGroundStyle)
			}
			.frame(square: 38)
			.background(.windowBackground, in: .circle)
		
		}

		private func action() async {
			await viewModel.send(.updateComposerSource(source))
		}
	}
}
