//
//  MsgCell.swift
//  Msgr
//
//  Created by Aung Ko Min on 22/10/22.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {
    private var layout: MsgCellLayout { viewModel.layout }
    @Environment(MsgCellViewModel.self) private var viewModel
    @Environment(\.sendMsgCellInteraction) private var sendMsgCellInteraction

    var body: some View {
        HStack(alignment: .bottom, spacing: 0) {
            leftView()
            MsgCellContentGesturesView(MsgCellContent())
            MsgCellOutgoingStatusView()
        }
        .allowsTightening(true)
        .equatable(by: viewModel.reloadID)
        .id(viewModel.id)
        .layoutValue(viewModel.msg.layoutValue)
    }

    @ViewBuilder
    private func leftView() -> some View {
        if !viewModel.isSender {
            ZStack(alignment: .bottom) {
                if layout.bubble.showAvatar, let sender = viewModel.sender() {
                    ProfilePhoto(
                        sender,
                        size: .custom(ChatLayoutConstants.Cell.defaultSpacing),
                        tapAction: .custom {
                            sendMsgCellInteraction?(.onTapAvatar(viewModel.id))
                        }
                    )
                    .equatable(by: sender.uid)
                }
            }
            .frame(width: ChatLayoutConstants.Cell.defaultSpacing + 4)
        }
    }
}
