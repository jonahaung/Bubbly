//
// Copyright © 2026 Aung Ko Min. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {

	// MARK: Internal

	let viewModel: MsgCellViewModel

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
			HStack(alignment: .bottom, spacing: 0) {
				if viewModel.state.isSender {
					Spacer(minLength: viewModel.state.attachments.isEmpty ? 50 : 120)
				} else {
					IncomingAccessory()
				}
				GestureAware {
					Content()
				}
				if viewModel.state.isSender {
					OutgoingAccessory()
				} else {
					Spacer(minLength: viewModel.state.attachments.isEmpty ? 50 : 120)
				}
			}

			if isSelected {
				Footer()
			}
		}
		.environment(\.isVisible, viewModel.state.isVisible)
		.environment(viewModel)
		.equatable(by: viewModel.state)
	}

	// MARK: Private

	private var isSelected: Bool {
		viewModel.state.isSelected
	}

	private var layout: MsgCellLayout {
		viewModel.state.layout
	}
}
