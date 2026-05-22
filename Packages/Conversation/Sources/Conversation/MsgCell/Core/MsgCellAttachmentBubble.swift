//  MsgCellAttachmentBubble.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI
import Database
import Services

struct MsgCellAttachmentBubble: View {
    let state: MsgCellViewModel.State
    let theme: ChatTheme
    var body: some View {
        VStack(alignment: state.horizontalAlignment, spacing: .zero) {
            MsgAttachmentsView(state: state)
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
