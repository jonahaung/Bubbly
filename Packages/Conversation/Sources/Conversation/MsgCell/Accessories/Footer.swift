//
// Copyright © 2026 Stream.io Inc. All rights reserved.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
	struct Footer: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var msg: Message {
			viewModel.msg
		}

		var body: some View {
			Text(footerText)
				.font(.caption)
				.padding(.horizontal, ChatLayoutConstants.Cell.defaultSpacing + 4 + 8)
				.allowsHitTesting(false)
		}
		private var footerText: String {
			if msg.isSender {
				let values = Array(msg.outgoingStatus.values)
				let descriptions: [String] = values.map(\.description)
				return descriptions.joined(separator: ", ")
			} else {
				return msg.date.formatted(date: .abbreviated, time: .shortened)
			}
		}
	}
}
