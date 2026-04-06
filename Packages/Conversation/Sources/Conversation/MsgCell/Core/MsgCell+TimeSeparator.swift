#if os(iOS)
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

        var body: some View {
			let date = viewModel.state.date
			Text(
				date, format: date.isInToday ? .dateTime
					.hour()
					.minute() : .dateTime
					.day()
					.weekday(.abbreviated)
					.hour()
					.minute()
			)
            .flexible(.horizontal)
			.frame(height: ChatLayoutConstants.Cell.timeSeparatorHeight, alignment: .center)
			.font(.footnote)
			.allowsHitTesting(false)
			.equatable(by: viewModel.state.id)
        }
    }
}

#endif
