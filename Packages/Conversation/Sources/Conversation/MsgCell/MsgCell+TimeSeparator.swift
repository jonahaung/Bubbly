//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TimeSeparator: View {
        @Environment(MsgCellViewModel.self) private var viewModel
        private var msg: Message {
            viewModel.msg
        }

        @Environment(\.typography) private var typography
        @Environment(\.conversationTheme) private var theme

        var body: some View {
            ZStack(alignment: .center) {
                Text(
                    msg.date.formatted(.dateTime.day().weekday(.abbreviated).hour().minute())
                )
                .fixedSize(horizontal: false, vertical: true)
                .padding(8)
                .background(theme.backgroundColor)
            }
            .flexible(.horizontal)
            .frame(height: ChatLayoutConstants.Cell.timeSeparatorHeight, alignment: .center)
            .font(typography.footnote)
            .equatable(by: msg.uid)
        }
    }
}
