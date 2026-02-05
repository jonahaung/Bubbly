//
//  MsgCell+TimeSeparater.swift
//  Conversation
//
//  Created by Aung Ko Min on 13/2/22.
//

import Core
import SwiftUI
import XUI
import Database
import Services

extension MsgCell {
	struct TimeSeparator: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var msg: Message { viewModel.msg }
		@Environment(\.typography) private var typography

		var body: some View {
			ZStack(alignment: .center) {
				Text(
					msg.date.formatted(.dateTime.day().weekday(.abbreviated).hour().minute())
				)
				.font(typography.footnote)
			}
			.flexible(.horizontal)
			.frame(height: ChatLayoutConstants.Cell.timeSeparatorHeight, alignment: .center)
			.equatable(by: msg.uid)
		}
	}
}
