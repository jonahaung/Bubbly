// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TimeSeparator: View {
        // MARK: Internal

        var body: some View {
            ZStack {
                if viewModel.state.isVisible {
                    let date = viewModel.state.date
                    Text(
                        date, format: date.isInToday ? .dateTime
                            .hour()
                            .minute() : .dateTime
                            .day()
                            .weekday(.abbreviated)
                            .hour()
                            .minute(),
                    )
                    .font(.system(size: UIFont.systemFontSize - 1, weight: .medium))
                    .foregroundStyle(Color.secondaryText)
                    .equatable(by: date)
                }
            }
            .flexible(.horizontal)
            .frame(height: ChatLayoutConstants.Cell.timeSeparatorHeight)
            .allowsHitTesting(false)
            .equatable(by: viewModel.state)
        }

        // MARK: Private

        @Environment(MsgCellViewModel.self) private var viewModel
    }
}
