// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Content: View {
        

        var body: some View {
            ZStack(
                alignment: .init(
                    horizontal: state.horizontalAlignment.inverted,
                    vertical: .top
                )
            ) {
                BubbleView()
                OverlayBubbleView()
            }
        }

        @Environment(MsgCellViewModel.self) private var viewModel
        private var state: MsgCellViewModel.State {
            viewModel.state
        }
    }

    struct OverlayBubbleView: View {
        

        var body: some View {
            Reactions(reactions: viewModel.state.reactions)
                .fixedSize()
                .equatable(by: viewModel.reloadID)
        }
        @Environment(MsgCellViewModel.self) private var viewModel
    }
}
