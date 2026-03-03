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
    @Environment(\.selectedMsg) private var selectedMsg

    private var isSelected: Bool {
        selectedMsg?.id == viewModel.id
    }

    private var layout: MsgCellLayout {
        viewModel.layout
    }

    @Environment(\.conversationTheme) private var theme

    var body: some View {
        VStack(alignment: viewModel.horizontalAlignment, spacing: 0) {
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
                if viewModel.isSender {
                    Spacer(minLength: viewModel.msg.attachments.isEmpty ? 50 : 100)
                } else {
                    IncomingAccessory()
                }
                GestureAware {
                    Content(viewModel: viewModel, theme: theme)
                }
                if viewModel.isSender {
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
        .equatable(by: viewModel.reloadID)
        .environment(\.viewIsVisible, viewModel.isVisible)
    }
}
