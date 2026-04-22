//  MsgCellAttachmentBubble.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI
import Database
import Services

struct MsgCellAttachmentBubble: View {
    @Environment(\.conversationTheme) private var theme
    let state: MsgCellViewModel.State
    var body: some View {
        VStack(alignment: state.horizontalAlignment, spacing: .zero) {
            MsgAttachmentsView(
                attachments: state.attachments,
                alignment: state.horizontalAlignment
            )

            if let attributedText = state.attributedText {
                TextContent(attributedText: attributedText)
                    .padding(theme.bubblePading)
                    .background(theme.bubbleColor(for: state.isSender))
                    .containerShape(RoundedRectangle(cornerRadius: Radius.md))
            }
        }
        .geometryGroup()
        .equatable(by: state.attachments)
    }
}
