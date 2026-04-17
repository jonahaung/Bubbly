// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

extension MsgCell {
	struct TextContent: View {
		

		var body: some View {
			if let text = state.attributedText {
				Text(text)
			}
		}

		

		@Environment(MsgCellViewModel.self) private var viewModel

		private var state: MsgCellViewModel.State {
			viewModel.state
		}
	}
}
