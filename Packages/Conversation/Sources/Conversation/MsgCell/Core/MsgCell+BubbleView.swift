//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Database
import Services
import SwiftUI

extension MsgCell {

	struct BubbleView: View {

		// MARK: Internal

		var body: some View {
			if !state.attachments.isEmpty {
				VStack(alignment: state.horizontalAlignment, spacing: 0) {
					MsgAttachmentsView(
						attachments: state.attachments,
						alignment: state.horizontalAlignment,
					)
					if state.text != nil {
						TextContent()
							.padding(theme.bubblePading)
							.background(theme.bubbleColor(for: state.isSender))
							.containerShape(bubbleShape)
					}
				}
			} else if state.text != nil {
				TextContent()
					.padding(theme.bubblePading)
					.background(theme.bubbleColor(for: state.isSender))
					.padding(theme.shadowPadding(for: state.isSender))
					.background(theme.shadowColor(for: state.isSender))
					.containerShape(bubbleShape)
			}
		}

		// MARK: Private

		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.conversationTheme) private var theme

		private var state: MsgCellViewModel.State {
			viewModel.state
		}

		private var bubbleShape: UnevenRoundedRectangle {
			state.bubbleCornor
				.roundedRectange(cornerRadius: theme.bubbleCornerRadius)
		}
	}
}
