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
                        size: .custom(Spacing.md),
						tapAction: .custom {
							msgCellActions?(.onTapAvatar(viewModel.id))
						},
					)
					.equatable(by: sender.uid)
				}
			}
            .frame(width: Spacing.md + 4)
            .equatable(by: viewModel.reloadID)
		}
	}
}
