// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

struct MsgCell: View {

    let viewModel: MsgCellViewModel

    var body: some View {
        VStack(
            alignment: viewModel.state.horizontalAlignment,
            spacing: 0
        ) {
            if layout.showTimeSeparator {
                TimeSeparator()
            }
            if layout.showTopPadding {
                CellSpacer()
            }
            if isSelected {
                Header()
            }
            HStack(alignment: .bottom, spacing: Spacing.xs) {
                if !viewModel.state.isSender {
                    IncomingAccessory()
                }
                GestureAware {
                    Content()
                }
                if viewModel.state.isSender {
                    OutgoingAccessory()
                }
            }

            if isSelected {
                Footer()
            }
        }
        .equatable(by: viewModel.reloadID)
        .environment(\.isVisible, viewModel.isVisible)
        .environment(viewModel)
        
    }

    private var isSelected: Bool {
        viewModel.state.isSelected
    }

    private var layout: MsgCellLayout {
        viewModel.state.layout
    }
}
