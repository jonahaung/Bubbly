//  MsgCell.swift
//
//  Copyright © 2026 Aung Ko Min.
//

import XUI
import Core
import SwiftUI
import Database
import Services

struct MsgCell: View {

    let viewModel: MsgCellViewModel

    var body: some View {
        VStack(alignment: viewModel.state.horizontalAlignment, spacing: 0) {
            MsgCellHeader(state: viewModel.state)
            HStack(alignment: .bottom, spacing: 0) {
                if !viewModel.state.isSender {
                    IncomingAccessory(state: viewModel.state)
                }
                MsgCellGesture {
                    MsgCellContent(state: viewModel.state)
                }
                if viewModel.state.isSender {
                    OutgoingAccessory(state: viewModel.state)
                }
            }
            .equatable(by: viewModel.state)
            MsgCellFooter(state: viewModel.state)
        }
        .environment(\.isVisible, viewModel.state.isVisible)
        .environment(viewModel)
    }
}
