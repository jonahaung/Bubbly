// © 2026 Aung Ko Min

import Database
import Services
import SwiftUI

extension MsgCell {
    struct BubbleView: View {
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
                }
                .geometryGroup()
            } else if state.attributedText != nil {
                TextContent()
                    .padding(theme.bubblePading)
                    .background(theme.bubbleColor(for: state.isSender))
                    .padding(
                        .init(
                            top: 0.2,
                            leading: state.isSender ? 0.5 : 0.1,
                            bottom: 0.7,
                            trailing: state.isSender ? 0.1 : 0.5,
                        ),
                    )
                    .background(Color.shadow)
                    .containerShape(bubbleShape)
            }
        }

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
