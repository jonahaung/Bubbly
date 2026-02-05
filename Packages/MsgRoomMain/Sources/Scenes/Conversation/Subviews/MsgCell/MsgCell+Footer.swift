//
//  MsgCell+Footer.swift
//  Conversation
//
//  Created by Aung Ko Min on 17/2/22.
//

import Core
import Database
import Services
import SwiftUI
import XUI

extension MsgCell {
	struct Footer: View {
		@Environment(MsgCellViewModel.self) private var viewModel
		private var msg: Message { viewModel.msg }
		@Environment(\.typography) private var typography

		var body: some View {
			let hPadding: CGFloat = ChatLayoutConstants.Cell.defaultSpacing + 4 + 8
			Text(footerText)
				.font(typography.caption1)
				.padding(.horizontal, hPadding)
				.equatable(by: msg.uid)
		}

		private var footerText: String {
			if msg.isSender {
				let values = Array(msg.outgoingStatus.values)
				let descriptions: [String] = values.map { $0.description }
				return descriptions.joined(separator: ", ")
			} else {
				return msg.date.formatted(date: .abbreviated, time: .shortened)
			}
		}
	}
}
