//  MsgCellAttachmentBubble.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI
import Database
import Services

struct MsgCellAttachmentBubble: View, @MainActor Equatable {
    
    static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.state.attachments == rhs.state.attachments
    }
    let state: MsgCellViewModel.State
    let theme: ChatTheme
    
    var body: some View {
        VStack(alignment: alignment, spacing: .zero) {
            MsgAttachmentsView(state: state)
            if let attributedText = state.attributedText, !attributedText.string.isWhitespace {
                Color.background.frame(height: 2)
                TextContent(attributedText: attributedText)
                    .multilineTextAlignment(.leading)
                    .padding(theme.bubblePading)
            }
        }
        .background(theme.bubbleColor(for: state.isSender))
        .clipShape(bubbleShape)
        .geometryGroup()
    }
    private var alignment: HorizontalAlignment {
        state.isSender ? state.horizontalAlignment.inverted : state.horizontalAlignment
    }
    private var bubbleShape: UnevenRoundedRectangle {
        state.bubbleCornor.roundedRectange(cornerRadius: theme.bubbleCornerRadius)
    }
}
