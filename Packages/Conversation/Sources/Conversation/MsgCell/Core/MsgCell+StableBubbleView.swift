//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Database
import Services
import SwiftUI

extension MsgCell {

    struct BubbleView: View {

        let state: MsgCellViewModel.State
        @Environment(\.conversationTheme) private var theme
        @Environment(\.isVisible) private var isVisible
		
        var body: some View {
            if !state.attachments.isEmpty {
                VStack(alignment: state.horizontalAlignment, spacing: 0) {
                    MsgAttachmentsView(
                        attachments: state.attachments,
                        alignment: state.horizontalAlignment
                    )

                    if let text = state.text, !text.isWhitespace {
                        TextContent(text: text)
                            .padding(state.bubblePadding)
                            .background {
                                bubbleBackground
                                    .padding(
                                        state.contentPadding
                                    )
                                    .background(
                                        Color(white: 0.85),
                                        in: .rect(corners: .concentric)
                                    )
                            }
                            .containerShape(bubbleShape)
                    }
                }
                .equatable(by: state)
            } else if let text = state.text {
                ZStack {
                    bubbleBackground
                        .padding(
                            state.contentPadding
                        )
                        .background(
                            Color(white: 0.85),
                            in: .rect(corners: .concentric)
                        )
                    TextContent(text: text)
                        .padding(state.bubblePadding)
                        .layoutPriority(1)
                }
                .containerShape(bubbleShape)
                .equatable(by: state)
            }
        }

        private var bubbleBackground: some View {
            ConcentricRectangle(corners: .concentric)
                .fill(state.isSender ? theme.outgoingBubbleColor : theme.incomingBubbleColor)
        }

        private var bubbleShape: UnevenRoundedRectangle {
            state.computeBubbleCorner()
                .roundedRectange(cornerRadius: theme.bubbleCornorRadius)
        }
    }
}
