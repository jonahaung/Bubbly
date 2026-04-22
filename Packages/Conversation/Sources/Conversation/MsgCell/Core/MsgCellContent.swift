//  MsgCellContent.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct MsgCellContent: View {
    var body: some View {
        ZStack(
            alignment: .init(
                horizontal: state.horizontalAlignment.inverted,
                vertical: .top
            )
        ) {
            if !state.attachments.isEmpty {
                MsgCellAttachmentBubble(state: state)
            } else {
                MsgCellTextBubble(state: state, theme: theme)
            }
            MsgCellReactionOverlay(reactions: state.reactions)
        }
    }

    @Environment(\.conversationTheme) private var theme
    let state: MsgCellViewModel.State
}
