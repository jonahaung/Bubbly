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
                MsgCellTextBubble(state: state)
            }
            MsgCellReactionOverlay(reactions: state.reactions)
        }
    }

    static func == (lhs: MsgCellContent, rhs: MsgCellContent) -> Bool {
        lhs.state == rhs.state
    }
}
