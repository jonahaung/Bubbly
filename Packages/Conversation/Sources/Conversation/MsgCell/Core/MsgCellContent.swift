//  MsgCellContent.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import SwiftUI
import Database
import Services

struct MsgCellContent: View {
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
                DispatchingChanges(to: state, id: state.id) { state in
                    MsgCellAttachmentBubble(state: state, theme: theme)
                }
            } else {
                MsgCellTextBubble(state: state, theme: theme)
            }
            MsgCellReactionOverlay(reactions: state.reactions)
        }
    }
}
