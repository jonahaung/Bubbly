// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {

    let viewModel: MsgCellViewModel

    var body: some View {
        VStack(alignment: viewModel.state.horizontalAlignment, spacing: 0) {
            MsgCellHeader(state: viewModel.state)
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                if !viewModel.state.isSender {
                    MsgCell.IncomingAccessory(state: viewModel.state)
                }
                MsgCellGesture {
                    MsgCellContent(state: viewModel.state)
                }
                if viewModel.state.isSender {
                    MsgCell.OutgoingAccessory(state: viewModel.state)
                }
            }.equatable(by: viewModel.state)
            MsgCellFooter(state: viewModel.state)
        }
        .environment(\.isVisible, viewModel.state.isVisible)
        .environment(viewModel)
    }
}
