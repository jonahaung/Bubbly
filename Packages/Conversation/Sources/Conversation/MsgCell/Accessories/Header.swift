
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
                .font(typography.caption1)
                .padding(.horizontal, 35)
                .fixedSize(horizontal: false, vertical: true)
				.allowsHitTesting(false)
                .equatable(by: state.id)
        }
    }
}
