//  MsgCellTextBubble.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import Core
import SwiftUI
import Database
import Services

struct MsgCellTextBubble: View, @MainActor Equatable {

    let state: MsgCellViewModel.State
    let theme: ChatTheme

    var body: some View {
        if let attributedText = state.attributedText {
            TextContent(attributedText: attributedText)
                .padding(theme.bubblePading)
                .background(theme.bubbleColor(for: state.isSender))
                .padding(
                    .init(
                        top: 0.2,
                        leading: state.isSender ? 0.7 : 0.2,
                        bottom: 0.7,
                        trailing: state.isSender ? 0.2 : 0.7
                    )
                )
                .background(Color.shadow)
                .padding(0.5)
                .background(Color.background)
                .containerShape(bubbleShape)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private var bubbleShape: UnevenRoundedRectangle {
        state.bubbleCornor.roundedRectange(cornerRadius: theme.bubbleCornerRadius)
    }

    static func == (lhs: MsgCellTextBubble, rhs: MsgCellTextBubble) -> Bool {
        lhs.state.bubbleCornor == rhs.state.bubbleCornor &&
        lhs.theme == rhs.theme &&
        lhs.state.attributedText == rhs.state.attributedText
    }

}

struct TextContent: View {
    var body: some View {
        Text(attributedText)
            .equatable(by: attributedText)
    }
    let attributedText: AttributedString
}
