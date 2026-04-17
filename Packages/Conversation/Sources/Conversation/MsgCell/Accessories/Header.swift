// © 2026 Aung Ko Min

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
    struct Header: View {
        @Environment(MsgCellViewModel.self) private var viewModel
        private var state: MsgCellViewModel.State {
            viewModel.state
        }

        @Environment(\.typography) private var typography

        private var headerText: String {
            if state.isSender {
                return state.date.formatted(date: .abbreviated, time: .shortened)
            } else {
                let name: String? = ContactsRepository.shared.contact(for: state.senderID)?.name
                return name ?? "Unknown"
            }
        }

        var body: some View {
            Text(headerText)
                .font(.system(size: UIFont.smallSystemFontSize, weight: .medium, design: .rounded))
                .foregroundStyle(Color.secondaryText)
                .padding(.horizontal, 35)
                .allowsHitTesting(false)
                .transition(.opacity)
                .equatable(by: state.id)
                .geometryGroup()
        }
    }
}
