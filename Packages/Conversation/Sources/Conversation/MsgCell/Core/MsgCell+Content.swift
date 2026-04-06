//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {

	struct Content: View {

		// MARK: Internal

		var body: some View {
			ZStack(
				alignment: .init(horizontal: state.horizontalAlignment.inverted, vertical: .top),
			) {
				BubbleView()
					.layoutPriority(1)
				OverlayBubbleView()
			}
			.foregroundStyle(state.foregroundStyle)
		}

		// MARK: Private

		@Environment(MsgCellViewModel.self) private var viewModel

		private var state: MsgCellViewModel.State {
			viewModel.state
		}
	}

	struct OverlayBubbleView: View {

		// MARK: Internal

		var body: some View {
			Reactions(reactions: viewModel.state.reactions)
				.fixedSize()
				.equatable(by: viewModel.state.reactions)
		}

		// MARK: Private

		@Environment(MsgCellViewModel.self) private var viewModel

		private var state: MsgCellViewModel.State {
			viewModel.state
		}
	}
}
