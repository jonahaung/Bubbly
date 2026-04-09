// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Footer: View {
        // MARK: Internal

        var body: some View {
            Text(footerText)
                .font(.caption)
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal, 35)
                .fixedSize(horizontal: false, vertical: true)
                .allowsHitTesting(false)
                .equatable(by: state.id)
        }

        // MARK: Private

        @Environment(MsgCellViewModel.self) private var viewModel

        private var state: MsgCellViewModel.State {
            viewModel.state
        }

        private var footerText: String {
            if state.isSender {
                state.msg.deliveryStatus.localizedName
            } else {
                state.date.formatted(date: .abbreviated, time: .shortened)
            }
        }
    }
}
