import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {

	let viewModel: MsgCellViewModel
	private var isSelected: Bool {
		viewModel.state.isSelected
	}

	var layout: MsgCellLayout { viewModel.state.layout }

	var body: some View {
		VStack(alignment: viewModel.state.horizontalAlignment, spacing: 0) {
			if layout.showTimeSeparator {
				TimeSeparator()
			}
			if layout.showTopPadding {
				CellSpacer()
			}
			if isSelected {
				Header()
			}
			HStack(alignment: .lastTextBaseline, spacing: 0) {
				if viewModel.state.isSender {
					Spacer(minLength: 50)
				} else {
					IncomingAccessory()
				}
				GestureAware {
					Content()
				}
				if viewModel.state.isSender {
					OutgoingAccessory()
				} else {
					Spacer(minLength: 50)
				}
			}

			if isSelected {
				Footer()
			}
		}
		.environment(\.isVisible, viewModel.state.isVisible)
		.onAppear {
			viewModel.setVisibility(true)
		}.onDisappear {
			viewModel.setVisibility(false)
		}
	}
}
