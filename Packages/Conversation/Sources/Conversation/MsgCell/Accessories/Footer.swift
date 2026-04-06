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
	struct Footer: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var msg: Message {
			viewModel.msg
		}

		var body: some View {
			Text(footerText)
				.font(.caption)
				.padding(.horizontal, 35)
				.fixedSize(horizontal: false, vertical: true)
				.allowsHitTesting(false)
				.equatable(by: msg.uid)
		}
		private var footerText: String {
			if msg.isSender {
				return msg.deliveryStatus.localizedName
			} else {
				return msg.date.formatted(date: .abbreviated, time: .shortened)
			}
		}
	}
}

#endif
