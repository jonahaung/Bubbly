// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TimeSeparator: View {
        

        var body: some View {
            let date = viewModel.state.date
            HStack(alignment: .firstTextBaseline, spacing: Spacing.sm) {
                if date.isInToday {
                    Text(date, style: .time)
                        .font(boldFont)
                } else {
                    if date.isInThisWeek {
                        if viewModel.state.isSender {
                            Text(
                                date,
                                format: .dateTime.weekday(.wide),
                            )
                            .font(normalFont)

                            Text(date, style: .time)
                                .font(boldFont)
                        } else {
                            Text(date, style: .time)
                                .font(boldFont)
                            Text(
                                date,
                                format: .dateTime.weekday(.wide),
                            )
                            .font(normalFont)
                        }
                    } else {
                        if date.isInThisMonth {
                            if viewModel.state.isSender {
                                Text(date, style: .time)
                                    .font(boldFont)
                                Text(
                                    date,
                                    format: .dateTime.day(.defaultDigits)
                                        .month(),
                                ).font(normalFont)

                            } else {
                                Text(
                                    date,
                                    format: .dateTime.day(.defaultDigits)
                                        .month(),
                                ).font(normalFont)
                                Text(date, style: .time)
                                    .font(boldFont)
                            }

                        } else {
                            if viewModel.state.isSender {
                                Text(date, style: .time)
                                    .font(boldFont)

                                Text(
                                    date,
                                    format: .dateTime.day(.defaultDigits)
                                        .month()
                                        .year(),
                                ).font(normalFont)
                            } else {
                                Text(
                                    date,
                                    format: .dateTime.day(.defaultDigits)
                                        .month()
                                        .year(),
                                ).font(normalFont)
                                Text(date, style: .time)
                                    .font(boldFont)
                            }
                        }
                    }
                }
            }
            .foregroundStyle(Color.quinaryText)
            .padding(
                viewModel.state.isSender ? .trailing : .leading,
                Padding.sm,
            )
            .padding(.horizontal, Padding.xl)
            .lineHeight(.multiple(factor: 1.2))
            .frame(
                height: ChatLayoutConstants.Cell.timeSeparatorHeight,
                alignment: .bottom,
            )
            .allowsHitTesting(false)
            .equatable(by: viewModel.id)
        }

        

        @Environment(MsgCellViewModel.self) private var viewModel

        private var boldFont: Font {
            Font.system(
                size: UIFont.preferredFont(forTextStyle: .title1).pointSize,
                weight: .semibold,
                design: .serif,
            )
            .width(.compressed)
            .smallCaps()
        }

        private var normalFont: Font {
            Font.system(
                size: UIFont.systemFontSize,
                weight: .regular,
                design: .default,
            )
            .width(.condensed)
        }
    }
}
