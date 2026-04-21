// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TimeSeparator: View {
        @Environment(\.typography) private var typography
        var body: some View {
            VStack {
                if let dateString = viewModel.state.dateStString {
                    Text(dateString)
                }
            }
            .font(typography.footnote.weight(.semibold))
            .foregroundStyle(Color.secondaryText)
            .frame(
                height: ChatLayoutConstants.Cell.timeSeparatorHeight
            )
            .flexible(.horizontal)
            .equatable(by: viewModel.reloadID)
        }
        @Environment(MsgCellViewModel.self) private var viewModel
    }
}
