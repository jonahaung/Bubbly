//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {

    struct Content: View {
        let state: MsgCellViewModel.State
        var body: some View {
            ZStack(
                alignment: .init(horizontal: state.horizontalAlignment.inverted, vertical: .top)
            ) {
                BubbleView(state: state)
                OverlayBubbleView(state: state)
            }
            .foregroundStyle(state.foregroundStyle)
            .equatable(by: state)
        }
    }

    struct OverlayBubbleView: View {
        let state: MsgCellViewModel.State
        var body: some View {
            if let reactions = state.reactions {
                Reactions(reactions: reactions)
                    .fixedSize()
                    .allowsHitTesting(false)
                    .equatable(by: reactions)
            }
        }
    }
}
