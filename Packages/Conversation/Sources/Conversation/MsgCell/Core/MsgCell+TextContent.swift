//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Services
import SwiftUI
import XUI

extension MsgCell {

	struct TextContent: View {

		// MARK: Internal

		var body: some View {
			if let text = state.text {
				Text(text)
					.fixedSize(horizontal: false, vertical: true)
			}
		}

		// MARK: Private

		@Environment(MsgCellViewModel.self) private var viewModel

		private var state: MsgCellViewModel.State {
			viewModel.state
		}
	}
}
