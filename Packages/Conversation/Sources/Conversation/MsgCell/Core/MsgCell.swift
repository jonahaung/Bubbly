//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {

    let viewModel: MsgCellViewModel
	@Environment(\.sharedNamespace) private var namespace
    private var isSelected: Bool {
        viewModel.state.isSelected
    }

    var body: some View {
        VStack(alignment: viewModel.state.horizontalAlignment, spacing: 0) {
            if viewModel.state.layout.showTimeSeparator {
                TimeSeparator()
            }
            if viewModel.state.layout.showTopPadding {
                CellSpacer()
            }
            if isSelected {
                Header()
            }
            HStack(alignment: .lastTextBaseline, spacing: 0) {
                if viewModel.state.isSender {
                    Spacer(minLength: viewModel.msg.attachments.isEmpty ? 50 : 100)
                } else {
                    IncomingAccessory()
                }
                GestureAware {
                    Content(state: viewModel.state)
						.matchedGeometryEffect(
							id: viewModel.id,
							in: namespace.unsafelyUnwrapped.value,
							anchor: .bottomTrailing,
							isSource: true
						)
                }
                if viewModel.state.isSender {
                    OutgoingAccessory()
                } else {
                    Spacer(minLength: viewModel.msg.attachments.isEmpty ? 50 : 100)
                }
            }
            if isSelected {
                Footer()
            }
        }
		.fixedSize(horizontal: false, vertical: true)
        .environment(\.isVisible, viewModel.state.isVisible)
		.equatable(by: viewModel.reloadID)
    }
}
