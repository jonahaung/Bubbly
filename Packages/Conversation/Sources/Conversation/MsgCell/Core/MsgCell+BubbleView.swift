//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI

extension MsgCell {

	struct BubbleView: View {

		@Environment(MsgCellViewModel.self) private var viewModel
		private var state: MsgCellViewModel.State { viewModel.state }
		@Environment(\.conversationTheme) private var theme
		
		var body: some View {
			if !state.attachments.isEmpty {
				VStack(alignment: state.horizontalAlignment, spacing: 0) {
					MsgAttachmentsView(
						attachments: state.attachments,
						alignment: state.horizontalAlignment
					)
					if state.text != nil {
						TextContent()
							.padding(theme.bubblePading)
							.background(theme.bubbleColor(for: state.isSender))
							.containerShape(bubbleShape)
					}
				}
//				.equatable(by: viewModel.id)
			} else if state.text != nil {
				TextContent()
					.padding(theme.bubblePading)
					.background(theme.bubbleColor(for: state.isSender))
					.padding(theme.shadowPadding(for: state.isSender))
					.background(theme.shadowColor(for: state.isSender))
//					.equatable(by: viewModel.id)
					.containerShape(bubbleShape)
//					.equatable(by: viewModel.reloadID)
			}
		}


		private var bubbleShape: UnevenRoundedRectangle {
			state.computeBubbleCorner()
				.roundedRectange(cornerRadius: theme.bubbleCornerRadius)
		}
	}
}
