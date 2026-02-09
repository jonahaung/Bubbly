//
//  MsgCell+IncomingAccessory.swift
//  MsgRoomMain
//
//  Created by Aung Ko Min on 15/1/26.
//

import Core
import Database
import Services
import SwiftUI

extension MsgCell {
	struct IncomingAccessory: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.msgCellActions) private var sendMsgCellInteraction
		private var layout: MsgCellLayout {
			viewModel.layout
		}

		var body: some View {
			ZStack(alignment: .bottom) {
				if layout.showAvatar, let sender = viewModel.sender() {
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
			.equatable(by: layout)
		}
	}
}
