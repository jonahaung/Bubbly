//  MsgCellContent.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct MsgCellContent: View, @MainActor Equatable {
    let state: MsgCellViewModel.State
    @Environment(\.conversationTheme) private var theme
    var body: some View {
        ZStack(
            alignment: .init(
                horizontal: state.horizontalAlignment.inverted,
                vertical: .top
            )
        ) {
            if state.attachments?.isEmpty == false {
                MsgCellAttachmentBubble(state: state)
            } else {
                MsgCellTextBubble(state: state, theme: theme)
            }
            MsgCellReactionOverlay(reactions: state.reactions)
        }
    }

    static func == (lhs: MsgCellContent, rhs: MsgCellContent) -> Bool {
        lhs.state.id == rhs.state.id
    }
}
