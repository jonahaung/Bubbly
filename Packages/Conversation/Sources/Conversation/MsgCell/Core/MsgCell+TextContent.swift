// © 2026 Aung Ko Min

import Services
import SwiftUI
import XUI

extension MsgCell {
    struct TextContent: View {
        // MARK: Internal

        var body: some View {
            if let text = state.attributedText {
                Text(text)
                    .allowsHitTesting(false)
            }
        }

        // MARK: Private

        @Environment(MsgCellViewModel.self) private var viewModel

        private var state: MsgCellViewModel.State {
            viewModel.state
        }
    }
}
