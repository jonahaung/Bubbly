// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI

extension MsgCell {
    struct BubbleView: View {
        // MARK: Internal

        var body: some View {
            if !state.attachments.isEmpty {
                VStack(alignment: state.horizontalAlignment, spacing: .zero) {
                    MsgAttachmentsView(
                        attachments: state.attachments,
                        alignment: state.horizontalAlignment,
                    )
                    if state.attributedText != nil {
                        TextContent()
                            .padding(theme.bubblePading)
                            .background(theme.bubbleColor(for: state.isSender))
                            .containerShape(bubbleShape)
                    }
                }.equatable(by: viewModel.state.attachments)
            } else if state.attributedText != nil {
                TextContent()
                    .padding(theme.bubblePading)
                    .background(theme.bubbleColor(for: state.isSender))
                    .padding(theme.shadowPadding(for: state.isSender))
                    .background(Color.shadow)
                    .containerShape(bubbleShape)
                    .equatable(by: viewModel.state.selectedMsg?.id == viewModel.id)
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
