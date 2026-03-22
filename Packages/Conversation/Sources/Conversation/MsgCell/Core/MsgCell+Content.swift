//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {

	struct Content: View {

		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.conversationTheme) private var theme
		private var state: MsgCellViewModel.State { viewModel.state }

		var body: some View {
			ZStack(
				alignment: .init(horizontal: state.horizontalAlignment.inverted, vertical: .top)
			) {
				BubbleView()
				OverlayBubbleView()
			}
			.foregroundStyle(state.foregroundStyle)
		}
	}

	struct OverlayBubbleView: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var state: MsgCellViewModel.State { viewModel.state }
		var body: some View {
			if viewModel.state.isVisible, let reactions = state.reactions {
				Reactions(reactions: reactions)
					.fixedSize()
					.allowsHitTesting(false)
			}
		}
	}
}
