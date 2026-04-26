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
                if !viewModel.state.isSender, let status = viewModel.state.incomingStatus {
                    IncomingAccessory(state: viewModel.state, status: status)
                        .equatable(by: viewModel.state)
                }
                MsgCellGesture(viewModel: viewModel) {
                    MsgCellContent(state: viewModel.state)
                }
                if viewModel.state.isSender {
                    OutgoingAccessory(state: viewModel.state)
                }
            }
            MsgCellFooter(state: viewModel.state)
        }
        .environment(\.isVisible, viewModel.isVisible)
    }
}
