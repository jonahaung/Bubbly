// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Footer: View {
        

        var body: some View {
            Text(footerText)
                .font(.system(size: UIFont.smallSystemFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal, 35)
                .allowsHitTesting(false)
                .transition(.opacity)
                .equatable(by: state.id)
        }

        

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
