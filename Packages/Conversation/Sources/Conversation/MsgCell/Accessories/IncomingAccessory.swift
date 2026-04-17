// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI

extension MsgCell {
	struct IncomingAccessory: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		@Environment(\.msgCellActions) private var msgCellActions
		private var layout: MsgCellLayout {
			viewModel.state.layout
		}

		var body: some View {
			ZStack(alignment: .bottom) {
                if layout.showAvatar, let sender = viewModel.state.sender {
					ProfilePhoto(
						sender,
						size: .custom(ChatLayoutConstants.Cell.defaultSpacing),
						tapAction: .custom {
							msgCellActions?(.onTapAvatar(viewModel.id))
						},
					)
					.equatable(by: sender.uid)
				}
			}
			.frame(width: ChatLayoutConstants.Cell.defaultSpacing + 4)
//            .padding(.leading, Padding.md)
            .equatable(by: layout.showAvatar)
		}
	}
}
