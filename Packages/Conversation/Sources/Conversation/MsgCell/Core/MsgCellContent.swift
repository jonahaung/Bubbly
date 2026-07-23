//  MsgCellContent.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct MsgCellContent: View {
    let viewModel: MsgCellViewModel
    @Environment(\.conversationTheme) private var theme

    private var state: MsgCellViewModel.State {
        viewModel.state
    }

    var body: some View {
        ZStack(
            alignment: .init(
                horizontal: state.horizontalAlignment.inverted,
                vertical: .top
            )
        ) {
            if state.attachments?.isEmpty == false {
                MsgCellAttachmentBubble(
                    state: state,
                    isVisible: viewModel.isVisible,
                    theme: theme
                )
            } else {
                MsgCellTextBubble(state: state, theme: theme)
            }
            MsgCellReactionOverlay(reactions: state.reactions)
        }
    }
}
