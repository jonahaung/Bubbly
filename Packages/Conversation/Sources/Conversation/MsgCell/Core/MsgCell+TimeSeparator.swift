// © 2026 Aung Ko Min

import Core
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TimeSeparator: View {

        var body: some View {
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                if let dateString = viewModel.state.dateStString {
                    Text(dateString)
                        .font(boldFont)
                        .multilineTextAlignment(.center)
                }
            }
            .foregroundStyle(Color.quinaryText)
            .padding(
                viewModel.state.isSender ? .trailing : .leading,
                Padding.sm,
            )
            .padding(.horizontal, Padding.xl)
            .lineHeight(.multiple(factor: 1.1))
            .frame(
                height: ChatLayoutConstants.Cell.timeSeparatorHeight,
                alignment: .bottom,
            ).equatable(by: viewModel.reloadID)
        }

        @Environment(MsgCellViewModel.self) private var viewModel

        private var boldFont: Font {
            Font.system(
                size: UIFont.buttonFontSize + 4,
                weight: .bold,
                design: .serif,
            ).width(.compressed)
                .smallCaps()
        }
    }
}
